class Standard
  # @!group CoilCoolingWaterToAirHeatPumpEquationFit

  # Prototype CoilCoolingWaterToAirHeatPumpEquationFit object
  # Enters in default curves for coil by type of coil
  # @param plant_loop [<OpenStudio::Model::PlantLoop>] the coil will be placed on the demand side of this plant loop
  # @param air_loop_node [<OpenStudio::Model::Node>] the coil will be placed on this node of the air loop
  # @param name [String] the name of the system, or nil in which case it will be defaulted
  # @param type [String] the type of coil to reference the correct curve set
  # @param cop [Double] rated cooling coefficient of performance
  def create_coil_cooling_water_to_air_heat_pump_equation_fit(model,
                                                              plant_loop,
                                                              air_loop_node: nil,
                                                              name: 'Water-to-Air HP Clg Coil',
                                                              type: nil,
                                                              cop: 3.4)

    clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)

    # add to air loop if specified
    clg_coil.addToNode(air_loop_node) unless air_loop_node.nil?

    # set coil name
    clg_coil.setName(name)

    # add to plant loop
    if plant_loop.nil?
      OpenStudio.logFree(OpenStudio::Error, 'openstudio.model.Model', 'No plant loop supplied for cooling coil')
      return false
    end
    plant_loop.addDemandBranchForComponent(clg_coil)

    # set coil cop
    if cop.nil?
      clg_coil.setRatedCoolingCoefficientofPerformance(3.4)
    else
      clg_coil.setRatedCoolingCoefficientofPerformance(cop)
    end

    # curve sets
    if type == 'OS default'
      # use OS default curves
    else # default curve set
      clg_coil.setTotalCoolingCapacityCoefficient1(-4.30266987344639)
      clg_coil.setTotalCoolingCapacityCoefficient2(7.18536990534372)
      clg_coil.setTotalCoolingCapacityCoefficient3(-2.23946714486189)
      clg_coil.setTotalCoolingCapacityCoefficient4(0.139995928440879)
      clg_coil.setTotalCoolingCapacityCoefficient5(0.102660179888915)
      clg_coil.setSensibleCoolingCapacityCoefficient1(6.0019444814887)
      clg_coil.setSensibleCoolingCapacityCoefficient2(22.6300677244073)
      clg_coil.setSensibleCoolingCapacityCoefficient3(-26.7960783730934)
      clg_coil.setSensibleCoolingCapacityCoefficient4(-1.72374720346819)
      clg_coil.setSensibleCoolingCapacityCoefficient5(0.490644802367817)
      clg_coil.setSensibleCoolingCapacityCoefficient6(0.0693119353468141)
      clg_coil.setCoolingPowerConsumptionCoefficient1(-5.67775976415698)
      clg_coil.setCoolingPowerConsumptionCoefficient2(0.438988156976704)
      clg_coil.setCoolingPowerConsumptionCoefficient3(5.845277342193)
      clg_coil.setCoolingPowerConsumptionCoefficient4(0.141605667000125)
      clg_coil.setCoolingPowerConsumptionCoefficient5(-0.168727936032429)
    end

    return clg_coil
  end

  # Finds lookup object in standards and return efficiency
  #
  # @param object: water to air heat pump cooling coil
  # @return [Double] full load efficiency (COP)
  def coil_cooling_water_to_air_heat_pump_standard_minimum_cop_crac(coil_cooling_water_to_air_heat_pump)
    search_criteria = {}
    search_criteria['template'] = template
    search_criteria['cooling_type'] = 'WaterCooled'
    search_criteria['heating_type'] = 'All Other'
    search_criteria['subcategory'] = 'CRAC'
    cooling_type = search_criteria['cooling_type']
    heating_type = search_criteria['heating_type']
    sub_category = search_criteria['subcategory']
    capacity_w = coil_cooling_water_to_air_heat_pump_find_capacity(coil_cooling_water_to_air_heat_pump)
    capacity_btu_per_hr = OpenStudio.convert(capacity_w, 'W', 'Btu/hr').get
    capacity_kbtu_per_hr = OpenStudio.convert(capacity_w, 'W', 'kBtu/hr').get

    # Look up the efficiency characteristics
    coil_props = model_find_object(standards_data['unitary_acs'], search_criteria, capacity_btu_per_hr, Date.today)

    cop = nil
    # If capacity is larger than 0
    if capacity_btu_per_hr > 0
      crac_minimum_scop = coil_props['minimum_scop']
      # If CRAC, use equations if coefficients are specified
      if sub_category == 'CRAC' && !crac_minimum_scop.nil?
        # cop = scop/sensible heat ratio
        # sensible heat ratio = sensible cool capacity/total cool capacity
        if coil_cooling_water_to_air_heat_pump.ratedSensibleCoolingCapacity.is_initialized
          crac_sensible_cool = coil_cooling_water_to_air_heat_pump.ratedSensibleCoolingCapacity.get
          crac_total_cool = coil_cooling_water_to_air_heat_pump.ratedTotalCoolingCapacity.get
          crac_sensible_cool_ratio = crac_sensible_cool / crac_total_cool
        elsif coil_cooling_water_to_air_heat_pump.autosizedRatedSensibleCoolingCapacity.is_initialized
          crac_sensible_cool = coil_cooling_water_to_air_heat_pump.autosizedRatedSensibleCoolingCapacity.get
          crac_total_cool = coil_cooling_water_to_air_heat_pump.autosizedRatedTotalCoolingCapacity.get
          crac_sensible_heat_ratio = crac_sensible_cool / crac_total_cool
        else
          OpenStudio.logFree(OpenStudio::Error, 'openstudio.standards.CoilCoolingWaterToAirHeatPumpEquationFit', 'Failed to get autosized sensible cool capacity')
        end
        cop = crac_minimum_scop / crac_sensible_heat_ratio
        cop = cop.round(2)
        OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.CoilCoolingWaterToAirHeatPumpEquationFit', "For #{coil_cooling_water_to_air_heat_pump.name}: #{cooling_type} #{heating_type} #{sub_category} Capacity = #{capacity_kbtu_per_hr.round}kBtu/hr; SCOP = #{crac_minimum_scop}")
      end
    end
    return cop
  end
end
