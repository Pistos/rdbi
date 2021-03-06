class RDBI::Statement
  extend MethLab

  attr_reader :dbh
  attr_reader :query
  attr_reader :mutex
  attr_reader :input_type_map

  attr_threaded_accessor :last_result

  inline(:finished, :finished?)   { @finished  }
  inline(:driver)                 { dbh.driver }

  inline(:new_execution) do |*args|
    raise NoMethodError, "this method is not implemented in this driver"
  end

  def initialize(query, dbh)
    @query = query
    @dbh   = dbh
    @mutex = Mutex.new
    @finished = false
    @input_type_map = RDBI::Type.create_type_hash(RDBI::Type::In)

    @dbh.open_statements.push(self)
  end

  def execute(*binds)
    raise StandardError, "you may not execute a finished handle" if @finished

    binds = binds.collect { |x| RDBI::Type::In.convert(x, @input_type_map) }

    mutex.synchronize do
      exec_args = *new_execution(*binds)
      self.last_result = RDBI::Result.new(self, binds, *exec_args)
    end
  end

  def finish
    mutex.synchronize do
      dbh.open_statements.reject! { |x| x.object_id == self.object_id }
      @finished = true
    end
  end
end

# vim: syntax=ruby ts=2 et sw=2 sts=2
