# Use caster base image
FROM caster/jmeter
MAINTAINER CasterHsu

# 更新 apt 套件管理系統的存儲庫，然後安裝 openssh-server 套件
RUN apt-get update && apt-get install -y openssh-server

# 將自定義啟動腳本覆制到容器內
COPY start.sh /start.sh

# 創建 SSH 伺服器需要的目錄
RUN mkdir /var/run/sshd

# 設定 root 用戶的密碼為 "aa123456"
RUN echo 'root:aa123456' | chpasswd

# 修改 SSH 伺服器的設定以允許 root 用戶透過密碼進行登入
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 修正 SSH 登入的問題，否則在登入後使用者會被踢出
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# 設定一個環境變數 NOTVISIBLE
ENV NOTVISIBLE "in users profile"

# 將 VISIBLE 環境變數添加到 /etc/profile 中
RUN echo "export VISIBLE=now" >> /etc/profile

# Ports to be exposed from the container for JMeter Master
EXPOSE 60000 22

# keep container alive
CMD ["/start.sh"]