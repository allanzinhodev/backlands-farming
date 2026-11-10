"""Independent failure and filesystem checks for coordinated asset saves."""
from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from backlands_editor import transactions
from backlands_editor.transactions import atomic_write_files


class TransactionTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.base = Path(self.temporary.name).resolve()
        self.assets = self.base / "assets"
        self.server = self.base / "server" / "data" / "items"

    def tearDown(self):
        self.temporary.cleanup()

    def originals(self) -> dict[Path, bytes]:
        originals = {
            self.assets / "Tibia.dat": b"original DAT",
            self.assets / "Tibia.spr": b"original SPR",
            self.assets / "Tibia.otfi": b"original OTFI",
            self.server / "items.otb": b"original OTB",
            self.server / "items.xml": b"original XML",
        }
        for path, data in originals.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        return originals

    def assert_no_stages(self):
        self.assertFalse(list(self.base.rglob(".backlands-stage-*")))

    def assert_originals(self, originals):
        for path, data in originals.items():
            self.assertEqual(path.read_bytes(), data, str(path))

    def test_cross_parent_save_stages_locally_and_preserves_all_original_backups(self):
        originals = self.originals()
        replacements = [(path, data.replace(b"original", b"changed"))
                        for path, data in originals.items()]
        real_replace = transactions.os.replace
        destinations = []

        def inspect_replace(source, target):
            source, target = Path(source), Path(target)
            self.assertEqual(source.parent.parent, target.parent)
            self.assertTrue(source.parent.name.startswith(".backlands-stage-"))
            destinations.append(target)
            return real_replace(source, target)

        with mock.patch.object(transactions.os, "replace", side_effect=inspect_replace):
            atomic_write_files(replacements, self.assets)

        self.assertEqual(destinations, list(originals))
        transaction_names = set()
        for path, data in originals.items():
            self.assertEqual(path.read_bytes(), data.replace(b"original", b"changed"))
            copies = list((path.parent / ".backups").glob("*/" + path.name))
            self.assertEqual(len(copies), 1)
            self.assertEqual(copies[0].read_bytes(), data)
            transaction_names.add(copies[0].parent.name)
        self.assertEqual(len(transaction_names), 1)
        self.assert_no_stages()

    def test_late_external_xml_failure_restores_dat_spr_otfi_and_otb(self):
        originals = self.originals()
        real_replace = transactions.os.replace
        did_fail = False

        def fail_xml_once(source, target):
            nonlocal did_fail
            if Path(target).name == "items.xml" and not did_fail:
                did_fail = True
                raise OSError("XML locked by another program")
            return real_replace(source, target)

        with mock.patch.object(transactions.os, "replace", side_effect=fail_xml_once):
            with self.assertRaisesRegex(OSError, "XML locked"):
                atomic_write_files([(path, b"changed") for path in originals], self.assets)

        self.assertTrue(did_fail)
        self.assert_originals(originals)
        self.assert_no_stages()

    def test_replace_that_raises_after_writing_also_restores_attempted_target(self):
        originals = self.originals()
        real_replace = transactions.os.replace
        did_fail = False

        def replace_then_fail(source, target):
            nonlocal did_fail
            result = real_replace(source, target)
            if Path(target).name == "items.xml" and not did_fail:
                did_fail = True
                raise OSError("interrupted after replacement")
            return result

        with mock.patch.object(transactions.os, "replace", side_effect=replace_then_fail):
            with self.assertRaisesRegex(OSError, "interrupted"):
                atomic_write_files([(path, b"changed") for path in originals], self.assets)

        self.assert_originals(originals)
        self.assert_no_stages()

    def test_failed_first_save_removes_only_new_target_files(self):
        self.assets.mkdir()
        keep = self.assets / "unrelated.txt"
        keep.write_bytes(b"keep me")
        entries = [(self.assets / "nested" / "Tibia.dat", b"new DAT"),
                   (self.server / "items.xml", b"new XML")]

        def fail_external(source, target):
            if Path(target).name == "items.xml":
                raise OSError("external destination unavailable")
            return real_replace(source, target)

        real_replace = transactions.os.replace
        with mock.patch.object(transactions.os, "replace", side_effect=fail_external):
            with self.assertRaises(OSError):
                atomic_write_files(entries, self.assets)

        self.assertFalse(any(path.exists() for path, _ in entries))
        self.assertEqual(keep.read_bytes(), b"keep me")
        self.assertFalse(list(self.base.rglob(".backups")))
        self.assert_no_stages()

    def test_staging_failure_leaves_originals_untouched(self):
        originals = self.originals()
        with mock.patch.object(transactions.os, "fsync", side_effect=OSError("disk full")):
            with self.assertRaisesRegex(OSError, "disk full"):
                atomic_write_files([(path, b"changed") for path in originals], self.assets)
        self.assert_originals(originals)
        self.assertFalse(list(self.base.rglob(".backups")))
        self.assert_no_stages()

    def test_preflight_rejection_before_staging_does_not_create_directories(self):
        preflight = mock.Mock(side_effect=ValueError("changed externally"))
        with self.assertRaisesRegex(ValueError, "changed externally"):
            atomic_write_files([(self.assets / "Tibia.dat", b"new")], self.assets, preflight)
        preflight.assert_called_once_with()
        self.assertFalse(self.assets.exists())

    def test_second_preflight_detects_conflict_before_any_target_replacement(self):
        originals = self.originals()
        preflight = mock.Mock(side_effect=[None, ValueError("changed while staging")])
        with mock.patch.object(transactions.os, "replace") as replace:
            with self.assertRaisesRegex(ValueError, "changed while staging"):
                atomic_write_files([(path, b"changed") for path in originals], self.assets, preflight)
        self.assertEqual(preflight.call_count, 2)
        replace.assert_not_called()
        self.assert_originals(originals)
        self.assert_no_stages()

    def test_duplicate_casefold_paths_rejected_before_creating_directories(self):
        with self.assertRaises(ValueError):
            atomic_write_files([(self.assets / "Tibia.dat", b"a"),
                                (self.assets / "TIBIA.DAT", b"b")], self.assets)
        self.assertFalse(self.assets.exists())

    def test_directory_and_ancestor_target_collisions_are_rejected(self):
        self.assets.mkdir()
        directory = self.assets / "directory"
        directory.mkdir()
        with self.assertRaises(ValueError):
            atomic_write_files([(directory, b"a")], self.assets)
        self.assertTrue(directory.is_dir())
        with self.assertRaises(ValueError):
            atomic_write_files([(self.assets / "new", b"a"),
                                (self.assets / "new" / "nested.dat", b"b")], self.assets)
        self.assertFalse((self.assets / "new").exists())
        self.assert_no_stages()

    def test_staging_root_cannot_also_be_a_new_target_file(self):
        with self.assertRaises(ValueError):
            atomic_write_files([(self.assets, b"a")], self.assets)
        self.assertFalse(self.assets.exists())

    def test_backup_copy_failure_prevents_every_target_replacement(self):
        originals = self.originals()
        with mock.patch.object(transactions.shutil, "copyfileobj", side_effect=OSError("backup full")):
            with mock.patch.object(transactions.os, "replace") as replace:
                with self.assertRaisesRegex(OSError, "backup full"):
                    atomic_write_files([(path, b"changed") for path in originals], self.assets)
        replace.assert_not_called()
        self.assert_originals(originals)
        self.assert_no_stages()

    def test_successful_first_save_can_create_distinct_nested_parents(self):
        entries = [(self.assets / "nested" / "Tibia.dat", b"DAT"),
                   (self.server / "items.xml", b"XML")]
        atomic_write_files(entries, self.assets)
        for path, data in entries:
            self.assertEqual(path.read_bytes(), data)
        self.assertFalse(list(self.base.rglob(".backups")))
        self.assert_no_stages()

    def create_link(self, link: Path, target: Path, *, directory: bool):
        try:
            link.symlink_to(target, target_is_directory=directory)
        except (OSError, NotImplementedError) as error:
            self.skipTest(f"Symbolic links unavailable: {error}")

    def test_escaping_backup_symlink_cannot_receive_original_data(self):
        originals = self.originals()
        outside = self.base / "outside"
        outside.mkdir()
        self.create_link(self.assets / ".backups", outside, directory=True)
        with self.assertRaisesRegex(ValueError, "backups"):
            atomic_write_files([(path, b"changed") for path in originals], self.assets)
        self.assert_originals(originals)
        self.assertFalse(list(outside.iterdir()))
        self.assert_no_stages()

    def test_symlink_target_is_rejected_without_modifying_its_destination(self):
        self.assets.mkdir()
        outside = self.base / "outside.dat"
        outside.write_bytes(b"original outside")
        link = self.assets / "Tibia.dat"
        self.create_link(link, outside, directory=False)
        with self.assertRaises(ValueError):
            atomic_write_files([(link, b"changed")], self.assets)
        self.assertTrue(link.is_symlink())
        self.assertEqual(outside.read_bytes(), b"original outside")
        self.assert_no_stages()

    def test_restore_failure_keeps_recovery_backups(self):
        originals = self.originals()
        first = next(iter(originals))
        real_replace = transactions.os.replace

        def fail_xml_and_dat_restore(source, target):
            if Path(target).name == "items.xml":
                raise OSError("XML write failed")
            if Path(target) == first and Path(source).name.startswith("restore-"):
                raise OSError("DAT recovery failed")
            return real_replace(source, target)

        with mock.patch.object(transactions.os, "replace", side_effect=fail_xml_and_dat_restore):
            with self.assertRaisesRegex(OSError, "Recupere os originais em .backups"):
                atomic_write_files([(path, b"changed") for path in originals], self.assets)
        copies = list((first.parent / ".backups").glob("*/" + first.name))
        self.assertEqual(len(copies), 1)
        self.assertEqual(copies[0].read_bytes(), originals[first])
        for path, data in originals.items():
            if path != first:
                self.assertEqual(path.read_bytes(), data)
        self.assert_no_stages()


if __name__ == "__main__":
    unittest.main()
