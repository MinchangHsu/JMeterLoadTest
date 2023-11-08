# JMeter – Performing Distributed Load Testing with Docker

**日期: 2023/11/06**

JMeter 是一個強大的開源工具，用於對網絡應用進行性能和負載測試。在單個 JMeter 實例生成的負載不足的情況下，可以使用主從架構將負載分發給多個 JMeter 實例。在本教程中，文章內容將指導您如何使用 Docker 容器設置 JMeter 主從架構。

### 先決條件

在開始之前，請確保您的系統上已安裝 Docker 和 Docker Compose。

JMeter 基底的 Dockerfile

在分散式測試中，確保所有環境都擁有相同版本的 Java、JMeter 和插件是至關重要的。主節點和從節點之間的唯一區別是所公開的埠和正在運行的進程。為了實現這個目標，我們創建了一個通用的 Dockerfile，我們將其稱為 `jmbase` 映像，其中包含主節點和從節點都通用的步驟。以下是構建基礎映像的步驟：

1. **選擇 Java 11 版本：** 我們使用了 `openjdk-11-jre-slim` 精簡版，以減小映像的大小。
2. **安裝實用工具：** 我們安裝了一些實用工具，如 `wget`、`unzip` 和 `telnet`。
3. **安裝 JMeter：** 我們下載並安裝了指定版本的 Apache JMeter（這裡使用的是版本 5.6）。
4. **使用版本變數：** 我們創建了一個版本變數 `JMETER_VERSION`，以便未來維護更加方便。
5. **添加插件文件夾：** 我們將所有自定義插件添加到 JMeter 的 `lib` 和 `lib/ext` 文件夾中。
6. **添加示例測試：** 我們添加了一個示例測試的文件夾。

```docker
# Use Java 11 slim JRE
FROM openjdk:11.0.11-jre-slim
MAINTAINER CasterHsu

# JMeter version
ARG JMETER_VERSION=5.6

# Install few utilities
RUN apt-get clean && \
    apt-get update && \
    apt-get -qy install \
                wget \
                telnet \
                iputils-ping \
                unzip \
                vim

# Install JMeter
RUN   mkdir /jmeter \
      && cd /jmeter/ \
      && wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
      && tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
      && rm apache-jmeter-$JMETER_VERSION.tgz

# ADD all the plugins
ADD plugins-lib /jmeter/apache-jmeter-$JMETER_VERSION/lib

## replace customer properties
ADD properties /jmeter/apache-jmeter-$JMETER_VERSION/bin

# ADD the sample test
ADD jmx jmx

# Set JMeter Home
ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/

# Add JMeter to the Path
ENV PATH $JMETER_HOME/bin:$PATH
```

Build base jmeter image

```bash
docker build -t caster/jmeter:latest -f ./jmeterBase_.Dockerfile .
```

這樣，我們已經成功創建了通用的 `jmbase` Docker 映像，並且可以在主節點和從節點中使用它，確保它們都具有相同的環境設置，以順利進行 JMeter 測試。

### JMeter Client/Master 的 Dockerfile：&#x20;

主節點的Docker文件應該繼承自基礎映像，並應該公開端口60000

```docker
# file name:jmmaster_.Dockerfile
# Use caster base image
FROM caster/jmeter
MAINTAINER CasterHsu

# Ports to be exposed from the container for JMeter Master
EXPOSE 60000

# keep container alive
CMD ["tail", "-f", "/dev/null"]
```

### JMeter Server/Slave 的 Dockerfile：

服務端的Docker文件應繼承自基礎映像，並應該公開端口1099和50000。jmeter-servert常駐運行

```docker
# file name:jmslave_.Dockerfile
# Use caster base image
FROM caster/jmeter

MAINTAINER CasterHsu

# Ports to be exposed from the container for JMeter Slaves/Server
EXPOSE 1099 50000

# Application to run on starting the container
ENTRYPOINT $JMETER_HOME/bin/jmeter-server

# keep container alive
CMD ["tail", "-f", "/dev/null"]
```

個別啟動 Master / Slava

```bash
docker build -t caster/jmmaster:latest -f ./jmmaster_.Dockerfile .
docker build -t caster/jmslave:latest -f ./jmslave_.Dockerfile .
```

## JMeter 分散式測試

啟動 JMeter Server 後，您可以知道 Server 在容器內部的 IP 地址。以這個範例為例，Slave 的 IP 是 '192.168.80.4'。

### 獲取容器 IP方式 一

您可以在日誌（log）內容中查找 IP 地址，通常位於 WARN 訊息後。以下是示例內容：

```log
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Created remote object: UnicastServerRef2 [liveRef: [endpoint:[192.168.80.4:46521](local),objID:[-21c30768:18bacbd9455:-7fff, 76839754569490693]]]
```

### 查找容器的 IP 地址二

要使用主從架構，您需要知道從容器的 IP 地址。您可以使用以下命令查找 IP 地址：

```bash
docker inspect --format '{{ .NetworkSettings.Networks.jmeternet.IPAddress }}' jmeter-master
docker inspect --format '{{ .NetworkSettings.Networks.jmeternet.IPAddress }}' jmeter-slave01
```

如果無法使用上述命令找到 IP 地址，您可以以 JSON 格式查看容器的所有信息：

```bash
docker inspect [容器名稱或 ID]
```

### 執行 JMeter 測試

*   **單個 JMeter 執行:** 使用以下命令運行單個 JMeter 測試：

    ```bash
    jmeter -n -t sample-test.jmx
    ```

    執行結果：

    ```log
    Creating summariser <summary>
    Created the tree successfully using sample-test.jmx
    Starting standalone test @ 2023 Nov 8 02:39:16 UTC (1699411156838)
    Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
    Warning: Nashorn engine is planned to be removed from a future JDK release
    summary +    143 in 00:00:13 =   11.1/s Avg:    57 Min:    45 Max:   172 Err:     0 (0.00%) Active: 5 Started: 5 Finished: 0
    summary +    238 in 00:00:17 =   14.1/s Avg:    56 Min:    43 Max:   160 Err:     0 (0.00%) Active: 0 Started: 5 Finished: 5
    summary =    381 in 00:00:30 =   12.8/s Avg:    56 Min:    43 Max:   172 Err:     0 (0.00%)
    Tidying up ...    @ 2023 Nov 8 02:39:46 UTC (1699411186924)
    ... end of run
    ```
*   **分散模式執行:** 若要在分散式模式下執行測試，您需要指定 Docker Slave 容器的內部 IP 地址，可以使用 `-R` 選項指定多個 IP 地址，以逗號分隔。

    ```bash
    jmeter -n -t sample-test.jmx -R 192.168.80.3,192.168.80.4
    ```

    執行結果：

    ```log
    Creating summariser <summary>
    Created the tree successfully using sample-test.jmx
    Configuring remote engine: 192.168.80.3
    Configuring remote engine: 192.168.80.4
    Starting distributed test with remote engines: [192.168.80.3, 192.168.80.4] @ 2023 Nov 8 02:41:03 UTC (1699411263848)
    Warning: Nashorn engine is planned to be removed from a future JDK release
    Remote engines have been started:[192.168.80.3, 192.168.80.4]
    Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
    summary +      1 in 00:00:00 =    2.1/s Avg:    91 Min:    91 Max:    91 Err:     0 (0.00%) Active: 2 Started: 2 Finished: 0
    summary +    312 in 00:00:34 =    9.2/s Avg:   702 Min:    45 Max:  5547 Err:    10 (3.21%) Active: 0 Started: 10 Finished: 10
    summary =    313 in 00:00:34 =    9.1/s Avg:   700 Min:    45 Max:  5547 Err:    10 (3.19%)
    Tidying up remote @ 2023 Nov 8 02:41:38 UTC (1699411298753)
    ... end of run
    ```

有錯誤應該是被google 阻擋，太頻繁訪問...如果是自己的server應該是沒有這問題，至少我有在測試一次自己的server.

這個示例的 `jmeter.properties` 文件已將 RMI SSL 連線關閉，如果您以後需要使用它，請自行調整屬性。現在，您已經具備了執行 JMeter 測試的基本知識，您可以在單台或分散式環境中開始執行測試。通過這些步驟，您可以使用 Docker 容器設置 JMeter 主從架構，從而更輕鬆地執行負載測試。

Slave 啟動錯誤回報RMI SSL&#x20;

```log
Error : java.io.FileNotFoundException: rmi_keystore.jks (No such file or directory)
```

RMI SSL 問題也可以參考官方文件操作: [前往](https://jmeter.apache.org/usermanual/remote-test.html#setup\_ssl)

### 參考來源

* [jmeter-distributed-load-testing-using-docker](https://www.testautomationguru.com/jmeter-distributed-load-testing-using-docker/)
