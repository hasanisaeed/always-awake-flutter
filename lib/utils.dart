/// Helper function to convert Map<String, dynamic> to a query string
String mapToQueryString(Map<String, dynamic> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
}
