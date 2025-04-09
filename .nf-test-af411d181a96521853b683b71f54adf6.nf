import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { HYPHY_PRIME } from '/Users/hverdonk/nf-core-capheine/modules/local/hyphy/prime/main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .addConverter(Path) { value -> value.toAbsolutePath().toString() } // Custom converter for Path. Only filename
        .build()

def jsonWorkflowOutput = new JsonGenerator.Options().excludeNulls().build()


workflow {

    // run dependencies
    

    // process mapping
    def input = []
    
                input[0] = [
                    [id: 'FBgn0000055_NT_033779.5_10_species_12_seqs-nodups'],
                    file(projectDir + '/tests/modules/local/hyphy/test_data/FBgn0000055_NT_033779.5_10_species_12_seqs-nodups.fasta', checkIfExists: true),
                    file(projectDir + '/tests/modules/local/hyphy/test_data/FBgn0000055_NT_033779.5_10_species_12_seqs-nodups.fasta.treefile', checkIfExists: true)
                ]
                
    //----

    //run process
    HYPHY_PRIME(*input)

    if (HYPHY_PRIME.output){

        // consumes all named output channels and stores items in a json file
        for (def name in HYPHY_PRIME.out.getNames()) {
            serializeChannel(name, HYPHY_PRIME.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = HYPHY_PRIME.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
  
}

def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonWorkflowOutput.toJson(result)
    
}
