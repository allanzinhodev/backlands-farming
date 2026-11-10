// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_KV_VALUE_WRAPPER_H
#define FS_KV_VALUE_WRAPPER_H

#include <string>
#include <vector>
#include <unordered_map>
#include <variant>
#include <optional>
#include <memory>
#include <algorithm>
#include <ranges>
#include <cstdint>

class ValueWrapper;

using StringType = std::string;
using BooleanType = bool;
using IntType = int32_t;
using DoubleType = double;
using ArrayType = std::vector<ValueWrapper>;
using MapType = std::unordered_map<std::string, std::shared_ptr<ValueWrapper>>;

using ValueVariant = std::variant<StringType, BooleanType, IntType, DoubleType, ArrayType, MapType>;

class ValueWrapper {
public:
	explicit ValueWrapper(uint64_t timestamp = 0);
	explicit(false) ValueWrapper(ValueVariant value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(const std::string &value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(const char* value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(bool value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(int32_t value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(double value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(const MapType &value, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(const std::initializer_list<std::pair<const std::string, ValueWrapper>> &init_list, uint64_t timestamp = 0);
	explicit(false) ValueWrapper(const std::initializer_list<ValueWrapper> &init_list, uint64_t timestamp = 0);

	static ValueWrapper deleted() {
		ValueWrapper wrapper;
		wrapper.setDeleted(true);
		return wrapper;
	}

	template <typename T>
	T get() const {
		static_assert(std::is_same_v<T, StringType> || std::is_same_v<T, BooleanType> || std::is_same_v<T, IntType> || std::is_same_v<T, DoubleType> || std::is_same_v<T, ArrayType> || std::is_same_v<T, MapType>, "Invalid type T");
		if (std::holds_alternative<T>(data_)) {
			return std::get<T>(data_);
		}
		return T {};
	}

	double getNumber() const {
		if (std::holds_alternative<IntType>(data_)) {
			return static_cast<double>(std::get<IntType>(data_));
		} else if (std::holds_alternative<DoubleType>(data_)) {
			return std::get<DoubleType>(data_);
		}
		return 0.0;
	}

	const ValueVariant &getVariant() const { return data_; }
	uint64_t getTimestamp() const { return timestamp_; }
	void setTimestamp(uint64_t timestamp) { timestamp_ = timestamp; }
	void setDeleted(bool deleted) { deleted_ = deleted; }
	bool isDeleted() const { return deleted_; }

	std::optional<ValueWrapper> get(const std::string &key) const;
	std::optional<ValueWrapper> get(size_t index) const;

	template <typename T>
	T get(const std::string &key) const;

	template <typename T>
	T get(size_t index) const;

	bool operator==(const ValueWrapper &rhs) const;

	// Serialization
	std::string serialize() const;
	static std::optional<ValueWrapper> deserialize(const char* data, size_t size, uint64_t timestamp = 0);

private:
	ValueVariant data_;
	uint64_t timestamp_ = 0;
	bool deleted_ = false;
};

template <typename T>
T ValueWrapper::get(const std::string &key) const {
	static_assert(std::is_same_v<T, StringType> || std::is_same_v<T, BooleanType> || std::is_same_v<T, IntType> || std::is_same_v<T, DoubleType> || std::is_same_v<T, ArrayType> || std::is_same_v<T, MapType>, "Invalid type T");
	auto optValue = get(key);
	if (optValue.has_value()) {
		if (auto pval = std::get_if<T>(&optValue->data_)) {
			return *pval;
		}
	}
	return T {};
}

template <typename T>
T ValueWrapper::get(size_t index) const {
	static_assert(std::is_same_v<T, StringType> || std::is_same_v<T, BooleanType> || std::is_same_v<T, IntType> || std::is_same_v<T, DoubleType> || std::is_same_v<T, ArrayType> || std::is_same_v<T, MapType>, "Invalid type T");
	auto optValue = get(index);
	if (optValue.has_value()) {
		if (auto pval = std::get_if<T>(&optValue->data_)) {
			return *pval;
		}
	}
	return T {};
}

inline bool ValueWrapper::operator==(const ValueWrapper &rhs) const {
	return data_ == rhs.data_;
}

#endif // FS_KV_VALUE_WRAPPER_H
