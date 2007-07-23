require 'rubygems/command'

# LockCommand will generate a list of +gem+ statements that will lock down the
# versions for the gem given in the command line.  It will specify exact
# versions in the requirements list to ensure that the gems loaded will always
# be consistent.  A full recursive search of all effected gems will be
# generated.
#
# Example:
#
#   gemlock rails-1.0.0 >lockdown.rb
#
# will produce in lockdown.rb:
#
#   require "rubygems"
#   gem 'rails', '= 1.0.0'
#   gem 'rake', '= 0.7.0.1'
#   gem 'activesupport', '= 1.2.5'
#   gem 'activerecord', '= 1.13.2'
#   gem 'actionpack', '= 1.11.2'
#   gem 'actionmailer', '= 1.1.5'
#   gem 'actionwebservice', '= 1.0.0'
#
# Just load lockdown.rb from your application to ensure that the current
# versions are loaded.  Make sure that lockdown.rb is loaded *before* any
# other require statements.
#
# Notice that rails 1.0.0 only requires that rake 0.6.2 or better be used.
# Rake-0.7.0.1 is the most recent version installed that satisfies that, so we
# lock it down to the exact version.
class Gem::Commands::LockCommand < Gem::Command

  def initialize
    super 'lock', 'generate a lockdown list of gems',
          :strict => false

    add_option '-s', '--[no-]strict',
               'fail if unable to satisfy a dependency' do |strict, options|
      options[:strict] = strict
    end
  end

  def complain(message)
    if options.strict then
      raise message
    else
      puts "# #{message}"
    end
  end

  def execute
    puts 'require "rubygems"'

    locked = {}

    pending = options[:args]

    until pending.empty? do
      full_name = pending.shift

      spec = Gem::SourceIndex.load_specification spec_path(full_name)

      puts "gem '#{spec.name}', '= #{spec.version}'" unless locked[spec.name]
      locked[spec.name] = true

      spec.dependencies.each do |dep|
        next if locked[dep.name]
        candidates = Gem.source_index.search dep.name, dep.requirement_list

        if candidates.empty? then
          complain "Unable to satisfy '#{dep}' from currently installed gems."
        else
          pending << candidates.last.full_name
        end
      end
    end
  end

  def spec_path(gem_full_name)
    File.join Gem.path, "specifications", "#{gem_full_name }.gemspec"
  end

  def usage # :nodoc:
    "#{program_name} [options] GEM_NAME-VERSION ..."
  end

end
