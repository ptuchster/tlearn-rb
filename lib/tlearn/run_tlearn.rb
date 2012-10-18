module TLearn
  class RunTLearn
    class UntrainedError < Exception; end;

    USE_EXTENSION = true
    
    TLEARN_EXECUTABLE = '../bin/tlearn'
  
    EXTERNAL_RESET_FILE = '-X'
    VERIFY_OUTPUTS_ON_EACH_SWEEP = '-V'
    USE_RTRL_TEMPORALLY_RECURRENT_LEARNING = '-L'
  
    def initialize(config = {})
      @config = Config.new(config)
    end
  
    def fitness(data, number_of_sweeps = @config.number_of_sweeps)
      raise UntrainedError.new("Train me first!") unless network_trained?

      clear_previous_fitness_session

      @config.setup_fitness_data(data)

      execute_tlearn_fitness(number_of_sweeps)
    end
  
    def train(training_data, number_of_sweeps = @config.number_of_sweeps)
      clear_entire_training_data
      
      @config.setup_config(training_data)
      @config.setup_training_data(training_data)

      execute_tlearn_train(number_of_sweeps)
          
      if training_successful?(number_of_sweeps)
        weights = File.read("#{Config::WORKING_DIR}/#{Config::TLEARN_NAMESPACE}.#{number_of_sweeps}.wts").split("\n")
        `cp #{Config::WORKING_DIR}/#{Config::TLEARN_NAMESPACE}.#{number_of_sweeps}.wts #{Config::WORKING_DIR}/#{Config::TLEARN_NAMESPACE}.wts`
        weights.map{|line| line.split("\t").map{|number| number.strip}}
      else
        false
      end
    end
    
    private
    
    def file_root
      "#{File.expand_path(Config::WORKING_DIR)}/#{Config::TLEARN_NAMESPACE}"
    end

    def clear_previous_fitness_session
      FileUtils.rm_f("#{Config::WORKING_DIR}/#{Config::TLEARN_NAMESPACE}.output")
      FileUtils.rm_f("#{Config::WORKING_DIR}/#{Config::TLEARN_NAMESPACE}.reset")
    end

    def clear_entire_training_data
      FileUtils.rm_f(Dir.glob("#{Config::WORKING_DIR}/*"))
    end
    
    def training_successful?(number_of_sweeps)
      File.exists?("#{file_root}.#{number_of_sweeps}.wts")
    end

    def network_trained?
      File.exists?("#{file_root}.wts")
    end
    
    def execute_tlearn_fitness(number_of_sweeps)
      if(USE_EXTENSION)
        TLearnExt.fitness({'sweeps' => number_of_sweeps, 'file_root' => file_root})
      else
        `cd #{Config::WORKING_DIR} && #{TLEARN_EXECUTABLE} -f #{Config::TLEARN_NAMESPACE} -l evaluator.wts -s #{number_of_sweeps} #{VERIFY_OUTPUTS_ON_EACH_SWEEP} > evaluator.output`
        
        output = File.read("#{Config::WORKING_DIR}/#{Config::TLEARN_NAMESPACE}.output")
        output.split("\n").map{|line| line.split("\t").map{|number| number.strip}}[-1]
      end
    end
  
    def execute_tlearn_train(number_of_sweeps)
      if(USE_EXTENSION)
        TLearnExt.train({'sweeps' => number_of_sweeps, 'file_root' => file_root})
      else
        `cd #{Config::WORKING_DIR} && #{TLEARN_EXECUTABLE} -f #{Config::TLEARN_NAMESPACE} #{USE_RTRL_TEMPORALLY_RECURRENT_LEARNING} -s #{number_of_sweeps}`
      end
    end

  end
end