<%@taglib prefix="s" uri="/struts-tags" %>
<html>
<head>
<title>List Results</title>
</head>
<body>
<form action="list" method="GET">
  <s:select label="Year" list="years" name="year" value="%{year}"/>
  <s:select label="Month" list="months" name="month" value="%{month}"/>
  <s:select label="Day" list="days" name="day" value="%{day}"/>
  <s:submit value="Submit"/>
</form>

<h2>Records</h2>
<table>
  <thead>
    <tr><th>id</th><th>Date</th><th>Source URL</th></tr>
  </thead>
  <tbody>
<s:iterator value="model">
  <tr>
    <td><a href="content/<s:property value="id"/>"><s:property value="id"/></a></td>
    <td><s:date name="dateEntered" format="dd/MM/yyyy"/></td>
    <td><s:property value="sourceUrl"/></td>
  </tr>
</s:iterator>
  </tbody>
</table>
</body>
</html>