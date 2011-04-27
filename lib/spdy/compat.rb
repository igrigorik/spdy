if Object.instance_methods.include? "type"
  class BinData::DSLMixin::DSLParser
    def name_is_reserved_in_1_8?(name)
      return false if name == "type"
      name_is_reserved_in_1_9?(name)
    end
    alias_method :name_is_reserved_in_1_9?, :name_is_reserved?
    alias_method :name_is_reserved?, :name_is_reserved_in_1_8?

    def name_shadows_method_in_1_8?(name)
      return false if name == "type"
      name_shadows_method_in_1_9?(name)
    end
    alias_method :name_shadows_method_in_1_9?, :name_shadows_method?
    alias_method :name_shadows_method?, :name_shadows_method_in_1_8?
  end
end
