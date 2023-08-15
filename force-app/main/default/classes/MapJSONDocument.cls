public class MapJSONDocument {

    @InvocableMethod(label='Map JSON output' description='map json to individual variables')
    public static List<ReturnVariables> MapJSONDocument(List<String> inputVariables ) {
        System.debug(inputVariables);
        return doMethod(inputVariables);

    }

    private static List<ReturnVariables> doMethod (List<String> input) {
        List<ReturnVariables> returnVarsList = new List<ReturnVariables>();

        ReturnVariables returnVars = new ReturnVariables();
        returnVars.FirstName = 'Kirk';
        returnVars.LastName = 'Leibert';
        returnVars.Credential = 'MD';
        returnVarsList.add(returnVars);
        return returnVarsList;

    }

    private String mapGetString(Map<String, Object> m, String p) {
        return String.valueOf(m.get(p));
    }

    private List<Object> mapGetList(Map<String, Object> m, String p) {
        return (List<Object>) (m.get(p));
    }

    private Map<String,Object> listGetMap(List<Object> l, Integer i) {
        return (Map<String,Object>) (l[i]);
    }

    private Map<String,Object> mapGetMap(Map<String, Object> m, String p) {
        return (Map<String,Object>) (m.get(p));
    }

    public class InputVariables{
        @invocableVariable    
        public List<String> Input;
    }

    public class ReturnVariables {
        @invocableVariable
        public String FirstName;    

        @invocableVariable    
        public String LastName;    
 
        @invocableVariable    
        public String Credential;      
    }
}