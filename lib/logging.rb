require 'logger'
require 'zlib'
require 'colorize'

# Provides logging to anything that +include+s it.
module Logging

  # All loggers and their names
  @loggers = {}

  # Returns an instance of {Logger} for the including module or class.
  #
  # If the including module or class implements the method +logger_name+, the return value is used for the logger name
  # instead of the name of the including module or class.
  #
  # @return [Logger] the logger for the including module or class
  def logger
    @logger ||= Logging.logger_for(self.respond_to?(:logger_name) ? self.logger_name : self.class.name)
  end

  # Log a Ruby Error using the logger.
  #
  # This is used to log the error message and the backtrace of the error through the logger.
  #
  # @param error [Exception] the exception to log
  def log_error(error)
    logger.error "Error: #{error.message}"
    error.backtrace.each { |line| logger.error line }
  end

  # Returns an instance of {Logger} for the provided class name.
  #
  # If a logger for the provided class name does not exist, a new one is created.
  #
  # @param class_name [String] the name of the class
  # @return [Logger] the logger for +class_name+
  def self.logger_for(class_name)
    @loggers[class_name] ||= create_logger_for(class_name)
  end

  # Returns a new logger for the provided class name.
  #
  # @param class_name [String] the name of the class
  # @return [Logger] a logger for +class_name+
  # @see .logger_for
  def self.create_logger_for(class_name)
    logger = Logger.new STDERR
    logger.progname = class_name
    logger.formatter = LogFormatter.new
    logger
  end

  # Called when the module is included and sets up a logger that can be accessed statically.
  #
  # @param base [Module] the module or class that included this module
  def self.included(base)
    base.define_singleton_method(:logger) do
      @logger ||= Logging.logger_for name
    end
  end

  private

  # Formats logging output for the logger used by {Logging}.
  class LogFormatter < Logger::Formatter

    # Retrieve the color for a severity.
    #
    # @param severity [String] the severity
    # @return [Symbol] the color for the severity
    def self.get_color(severity)
      case severity
      when 'DEBUG' then :light_blue
      when 'WARN'  then :magenta
      when 'INFO'  then :cyan
      when 'ERROR' then :light_red
      when 'FATAL' then :light_red
      else :default
      end
    end

    # Format a log message.
    #
    # @param severity [String] the severity of the message
    # @param time     [Time]   the time of the message
    # @param progname [String] the name of the logger
    # @param msg      [String] the value of the message
    # @return [String] a formatted log message
    def call(severity, time, progname, msg)

      # Get the color for the severity
      color = LogFormatter.get_color severity

      # Eliminate some colors to ensure that the progname color is easy to see
      possible_colors = String.color_codes.keys.delete_if do |sym|
        sym.include?(:black) || sym.include?(:default) || !sym.include?(:light)
      end

      # Get a crc32 of the name (never changes for a set name) and mod it with the number of possible colors.
      # This gives us the index of a color, which is then used to look up the color from possible colors.
      progname_color = possible_colors[Zlib.crc32(progname) % possible_colors.length]

      # Format time as HH:MM:SS
      time = time.strftime '%H:%M:%S'

      # Color severity and progname using colorize
      colored_severity = severity.colorize color
      colored_progname = progname.colorize progname_color

      # Return format as "HH:MM:SS [SEVERITY] [PROGNAME]: MESSAGE"
      "#{time} [#{colored_severity}] [#{colored_progname}]: #{msg}\n"
    end
  end
end
