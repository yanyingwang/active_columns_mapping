module ActiveRecord
  module QueryMethods
    def where!(opts, *rest) # :nodoc:
      opts = sanitize_forbidden_attributes(opts)
      references!(PredicateBuilder.references(opts)) if Hash === opts

      ## make columns_mapping work
      nopts = opts.map do |k, v|
        nk = if columns_mapping.key(k.to_s).present?
               columns_mapping.key(k.to_s).to_sym
             else
               k
             end
        [nk, v]
      end.to_h

      self.where_clause += where_clause_factory.build(nopts, rest)
      self
    end

  end
end