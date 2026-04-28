abstract class SalesforceConfig {
  static const String instanceUrl =
      'https://orgfarm-0598e59cb2.test2.my.pc-rnd.salesforce.com';
  static const String apiVersion = 'v65.0';

  // OAuth 2.0 client credentials (used for both REST API and Agentforce)
  static const String clientId =
      '3MVG9MEaDIAQrzQmBMnBV6msQVEPXldyXdj1btnQUJjNrNYzaH7f4VtuaksdIDhomNSg1HtfvUUDbyTWhi_3a';
  static const String clientSecret =
      '061E772EBCFFA740B9A2158DFBDB1C96D374901ED559E72BED2A87C86B9EF330';

  // Agentforce
  static const String agentId = '0XxoB000000AhLRSA0';
  static const String agentApiBaseUrl =
      'https://test.api.salesforce.com/einstein/ai-agent/v1';
}
