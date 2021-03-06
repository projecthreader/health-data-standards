module HealthDataStandards
  module Import
    module C32
      class ConditionImporter < SectionImporter
        
        def initialize
          @entry_xpath = "//cda:section[cda:templateId/@root='2.16.840.1.113883.3.88.11.83.103']/cda:entry/cda:act/cda:entryRelationship/cda:observation"
          @code_xpath = "./cda:value"
          @status_xpath = "./cda:entryRelationship/cda:observation[cda:templateId/@root='2.16.840.1.113883.10.20.1.50']/cda:value"
          @description_xpath = "./cda:text/cda:reference[@value]"
        end
        
        def create_entries(doc, id_map = {})
          @id_map = id_map
          condition_list = []
          entry_elements = doc.xpath(@entry_xpath)
          
          entry_elements.each do |entry_element|
            condition = Condition.new
            
            extract_codes(entry_element, condition)
            extract_dates(entry_element, condition)
            extract_status(entry_element, condition)
            extract_description(entry_element, condition, id_map)
            extract_cause_of_death(entry_element, condition)
            extract_type(entry_element, condition)

            entry_element.xpath("./cda:act[cda:templateId/@root='2.16.840.1.113883.10.20.1.27']/cda:performer").each do |provider_element|
              condition.treating_provider < import_actor(provider_element)
            end

            condition_list << condition
          end
          
          condition_list
        end

        private

        def extract_cause_of_death(entry_element, condition)
          cod = entry_element.at_xpath("./cda:entryRelationship[@typeCode='CAUS']/cda:observation/cda:code[@code='419620001']")
          condition.cause_of_death = cod.present?
        end

        def extract_type(entry_element, condition)
          code_element = entry_element.at_xpath('./cda:code')
          if code_element
            condition.type = case code_element['code']
                               when '404684003'  then 'Finding'
                               when '418799008'  then 'Symptom'
                               when '55607006'   then 'Problem'
                               when '409586006'  then 'Complaint'
                               when '64572001'   then 'Condition'
                               when '282291009'  then 'Diagnosis'
                               when '248536006'  then 'Functional limitation'
                               else nil
                             end
          end
        end

      end
    end
  end
end
