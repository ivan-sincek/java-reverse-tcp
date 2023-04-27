<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>
<%-- Works on Linux OS, macOS and Windows OS. --%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Simple Java Web Shells</title>
        <meta name="author" content="Ivan Šincek">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            html {
                height: 100%;
            }
            body {
                background-color: #F8F8F8;
                display: flex;
                flex-direction: column;
                margin: 0;
                height: inherit;
                color: #262626;
                font-family: Arial, Helvetica, sans-serif;
                font-size: 1em;
                font-weight: 400;
                text-align: left;
            }
            .home {
                display: flex;
                justify-content: center;
                flex: 1 0 auto;
                padding: 1em;
            }
            .links {
                margin: 0;
                padding: 0;
                list-style-type: none;
            }
            .links li {
                margin-top: 1em;
                text-align: center;
            }
            .links li a {
                color: #000;
                font-size: 1.2em;
                text-decoration: none;
                cursor: pointer;
            }
            .links li a:hover {
                text-decoration: underline;
            }
        </style>
    </head>
    <body>
        <div class="home">
            <ul class="links">
		<li><a href="./jsp_reverse_shell.jsp">JSP Reverse Shell</a></li>
                <li><a href="./simple_jsp_web_shell_post.jsp">Simple JSP Web Shell POST</a></li>
                <li><a href="./simple_jsp_web_shell_get.jsp?command=dir">Simple JSP Web Shell GET</a></li>
                <li><a href="./files.jsp">JSP File Upload/Download Script</a></li>
            </ul>
        </div>
    </body>
</html>
