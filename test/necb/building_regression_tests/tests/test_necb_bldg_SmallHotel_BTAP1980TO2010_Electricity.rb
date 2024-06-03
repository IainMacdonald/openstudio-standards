require_relative '../../../helpers/minitest_helper'
require_relative '../../../helpers/compare_models_helper'
require_relative '../resources/regression_helper'

class Test_SmallHotel_BTAP1980TO2010_Electricity < NECBRegressionHelper
  def setup()
    super()
  end

  def test_BTAP1980TO2010_SmallHotel_regression_Electricity()
    result, diff = create_model_and_regression_test(
      building_type:        'SmallHotel',
      primary_heating_fuel: 'Electricity', 
      epw_file:             'CAN_AB_Calgary.Intl.AP.718770_CWEC2020.epw',
      template:             'BTAP1980TO2010', 
      run_simulation:       false
    )
    if result == false
      puts "JSON terse listing of diff-errors."
      puts diff
      puts "Pretty listing of diff-errors for readability."
      puts JSON.pretty_generate( diff )
      puts "You can find the saved json diff file here test/necb/building_regression_tests/expected_results/SmallHotel-BTAP1980TO2010-Electricity_CAN_AB_Calgary.Intl.AP.718770_CWEC2020_diffs.json"
      puts "outputing errors here. "
      puts diff["diffs-errors"] if result == false
    end
    assert(result, diff)
  end
end