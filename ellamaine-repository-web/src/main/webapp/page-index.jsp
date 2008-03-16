<%@taglib prefix="s" uri="/struts-tags" %>
<html>
<head>
<title>Page Results</title>
</head>
<body>
Page No: <s:property value="pageNo"/><br/>
Page Size: <s:property value="pageSize"/><br/>
<s:if test="next">
  <a href="page?pageNo=<s:property value="nextPageNo"/>&pageSize=<s:property value="pageSize"/>">Next Page</a>
</s:if>
<s:if test="previous">
  <a href="page?pageNo=<s:property value="prevPageNo"/>&pageSize=<s:property value="pageSize"/>">Previous Page</a>
</s:if>
<h2>Records</h2>
<table>
  <thead>
    <tr><th>id</th><th>Date</th><th>Source URL</th></tr>
  </thead>
  <tbody>
<s:iterator value="pageResults" var="page">
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