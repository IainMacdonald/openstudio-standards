require_relative '../../helpers/minitest_helper'

class TestConstructionsInformation < Minitest::Test
  def setup
    @create = OpenstudioStandards::CreateTypical
    @constructions = OpenstudioStandards::Constructions
  end

  def test_film_coefficients_r_value
    # Film values from 90.1-2010 A9.4.1 Air Films
    film_ext_surf_r_ip = 0.17
    film_semi_ext_surf_r_ip = 0.46
    film_int_surf_ht_flow_up_r_ip = 0.61
    film_int_surf_ht_flow_dwn_r_ip = 0.92
    fil_int_surf_vertical_r_ip = 0.68

    film_ext_surf_r_si = OpenStudio.convert(film_ext_surf_r_ip, 'ft^2*hr*R/Btu', 'm^2*K/W').get
    film_semi_ext_surf_r_si = OpenStudio.convert(film_semi_ext_surf_r_ip, 'ft^2*hr*R/Btu', 'm^2*K/W').get
    film_int_surf_ht_flow_up_r_si = OpenStudio.convert(film_int_surf_ht_flow_up_r_ip, 'ft^2*hr*R/Btu', 'm^2*K/W').get
    film_int_surf_ht_flow_dwn_r_si = OpenStudio.convert(film_int_surf_ht_flow_dwn_r_ip, 'ft^2*hr*R/Btu', 'm^2*K/W').get
    fil_int_surf_vertical_r_si = OpenStudio.convert(fil_int_surf_vertical_r_ip, 'ft^2*hr*R/Btu', 'm^2*K/W').get

    result = @constructions.film_coefficients_r_value('AtticFloor', true, true)
    assert_in_delta(film_int_surf_ht_flow_up_r_si + film_semi_ext_surf_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('AtticWall', true, true)
    assert_in_delta(film_ext_surf_r_si + film_semi_ext_surf_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('InteriorCeiling', true, true)
    assert_in_delta(film_int_surf_ht_flow_dwn_r_si + film_int_surf_ht_flow_up_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('ExteriorRoof', true, true)
    assert_in_delta(film_ext_surf_r_si + film_int_surf_ht_flow_up_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('ExteriorFloor', true, true)
    assert_in_delta(film_ext_surf_r_si + film_int_surf_ht_flow_dwn_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('ExteriorWall', true, true)
    assert_in_delta(film_ext_surf_r_si + fil_int_surf_vertical_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('GroundContactFloor', true, true)
    assert_in_delta(film_int_surf_ht_flow_dwn_r_si, result, 0.001)
    result = @constructions.film_coefficients_r_value('GroundContactWall', true, true)
    assert_in_delta(fil_int_surf_vertical_r_si, result, 0.001)
  end

  def test_construction_simple_glazing?
    model = OpenStudio::Model::Model.new
    simple_glazing = OpenStudio::Model::SimpleGlazing.new(model)
    construction = OpenStudio::Model::Construction.new(model)
    construction.setLayers([simple_glazing])
    assert(@constructions.construction_simple_glazing?(construction))

    op_mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    construction.setLayers([op_mat])
    assert(!@constructions.construction_simple_glazing?(construction))
  end

  def test_construction_get_conductance
    model = OpenStudio::Model::Model.new
    construction = OpenStudio::Model::Construction.new(model)
    material1 = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'MediumRough', 0.12, 2.0, 2322, 832)
    material2 = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'MediumRough', 0.09, 1.5, 2322, 832)
    calc = 1.0 / ((1.0 / (2.0 / 0.12)) + (1.0 / (1.5 / 0.09)))
    construction.setLayers([material1, material2])
    assert_in_delta(calc, @constructions.construction_get_conductance(construction), 0.0001)

    simple_glazing = OpenStudio::Model::SimpleGlazing.new(model, 0.2, 0.40)
    construction.setLayers([simple_glazing])
    assert_in_delta(0.2, @constructions.construction_get_conductance(construction), 0.0001)

    material1 = OpenStudio::Model::Gas.new(model, 'Air', 0.01)
    material2 = OpenStudio::Model::StandardGlazing.new(model, 'SpectralAverage', 0.1)
    construction.setLayers([material2, material1, material2])
    assert_in_delta(0.0247, @constructions.construction_get_conductance(construction, temperature: 10.0), 0.0001)
  end

  def test_construction_get_solar_reflectance_index
    model = OpenStudio::Model::Model.new
    layers = OpenStudio::Model::MaterialVector.new
    layers << OpenStudio::Model::StandardOpaqueMaterial.new(model, 'MediumRough', 0.0889, 2.31, 2322, 832)
    construction = OpenStudio::Model::Construction.new(model)
    construction.setLayers(layers)
    sri = @constructions.construction_get_solar_reflectance_index(construction)
    assert(sri  > 0)
  end

  def test_construction_set_get_constructions
    model = OpenStudio::Model::Model.new
    building_type = 'PrimarySchool'
    template = '90.1-2013'
    climate_zone = 'ASHRAE 169-2013-4A'
    @create.create_space_types_and_constructions(model, building_type, template, climate_zone)
    default_construction_set = model.getDefaultConstructionSets[0]
    construction_array = @constructions.construction_set_get_constructions(default_construction_set)
    assert(construction_array.size > 2)
  end
end