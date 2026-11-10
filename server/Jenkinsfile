pipeline {
    agent any

    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                    sudo apt update
                    sudo apt install -y git wget cmake build-essential pkg-config \
                        libmysqlclient-dev libpugixml-dev libfmt-dev libssl-dev \
                        libspdlog-dev libmimalloc-dev libabsl-dev libasio-dev zlib1g-dev
                '''
                sh '''
                    cd /tmp
                    wget https://www.lua.org/ftp/lua-5.5.0.tar.gz
                    tar -xzf lua-5.5.0.tar.gz
                    cd lua-5.5.0
                    make linux
                    sudo make install
                    lua -v
                '''
                sh '''
                    if [ -d "$HOME/simdutf" ]; then
                        cd "$HOME/simdutf"
                        git pull --ff-only
                    else
                        git clone https://github.com/simdutf/simdutf.git "$HOME/simdutf"
                        cd "$HOME/simdutf"
                    fi
                    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME/.local
                    cmake --build build -- -j$(nproc)
                    cmake --install build
                '''
                sh '''
                    if [ -d "$HOME/mio" ]; then
                        cd "$HOME/mio"
                        git pull --ff-only
                    else
                        git clone https://github.com/mandreyel/mio.git "$HOME/mio"
                        cd "$HOME/mio"
                    fi
                    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME/.local
                    cmake --build build -- -j$(nproc)
                    cmake --install build
                '''
            }
        }

        stage('Update') {
            steps {
                sh '''
                    git remote set-url upstream https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60.git 2>/dev/null || \
                    git remote add upstream https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60.git
                    git fetch upstream main
                    git checkout main
                    git reset --hard upstream/main
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    rm -rf build-release
                    mkdir build-release
                    cd build-release
                    cmake -DCMAKE_BUILD_TYPE=Release \
                        -DDISABLE_STATS=1 \
                        -DENABLE_SLOW_TASK_DETECTION=ON \
                        -DUSE_MIMALLOC=ON \
                        -DLUA_INCLUDE_DIR=/usr/local/include \
                        -DLUA_LIBRARY=/usr/local/lib/liblua.a \
                        -DLUA_LIBRARIES="/usr/local/lib/liblua.a;m;dl" \
                        -DLUA_VERSION_STRING=5.5.0 \
                        -DCMAKE_PREFIX_PATH="/usr/local;$HOME/.local" \
                        ..
                    cmake --build . -- -j$(nproc)
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh './deploy.sh'
            }
        }
    }
}
