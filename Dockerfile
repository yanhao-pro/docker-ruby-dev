FROM ruby:2.4.0
MAINTAINER Yanhao Yang <yanhao.yang@gmail.com>

# Development tools
RUN \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get update && \
  apt-get install -y nodejs && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  # for build vim
  python-dev libncurses5-dev libncursesw5-dev \
  python3-dev ruby-dev lua5.1 liblua5.1-dev \
  zsh silversearcher-ag curl nginx locales sudo \
  && \
  apt-get autoremove -y && \
  apt-get autoclean && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY files/rtags /usr/local/bin/rtags
COPY files/nginx.conf /etc/nginx/nginx.conf
COPY files/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init

RUN \
  chsh --shell /bin/zsh && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
  locale-gen && \
  groupadd --gid 1000 docker && \
  useradd --gid 1000 --uid 1000 --create-home docker && \
  echo "docker ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
  chmod 0440 /etc/sudoers.d/user && \
  chown -R docker:docker /var/lib/nginx && \
  chown -R docker:docker /var/log/nginx && \
  chmod +x /usr/local/bin/dumb-init && \
  # build vim
  cd /tmp && \
  git clone https://github.com/vim/vim.git && \
  cd /tmp/vim && \
  ./configure \
    --with-features=huge \
    --enable-multibyte \
    --enable-rubyinterp=yes \
    --enable-pythoninterp=yes \
    --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
    --enable-python3interp=yes \
    --with-python3-config-dir=/usr/lib/python3.4/config-3.4m-x86_64-linux-gnu \
    --enable-luainterp=yes \
    --enable-cscope \
  && \
  make && \
  make install && \
  cd ~ && \
  rm -rf /tmp/*

ENV TERM=xterm-256color

# To make oh-my-zsh installer happy
ENV SHELL=/usr/bin/zsh

USER docker

RUN \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
  git clone https://github.com/YanhaoYang/vim-for-ruby.git ~/.vim && \
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
  ~/.fzf/install --all

COPY files/.zshrc /home/docker/.zshrc

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
