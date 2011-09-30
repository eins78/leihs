# == Schema Information
#
# Table name: languages
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  locale_name :string(255)
#  default     :boolean(1)
#  active      :boolean(1)
#

class Language < ActiveRecord::Base
  
  default_scope order(:name)
  scope :active_languages, where(:active => true)
  
  validates_uniqueness_of :default, :if => Proc.new { |l| l.default }
  
  def self.default_language 
    Language.where(:default => true).first || Language.first
  end
  
  def self.prefered(accepted_languages)
    default = default_language.locale_name.dasherize
    
    return default if accepted_languages.nil?
    
    accepted_languages = accepted_languages.split(",").map { |x| x.strip.split(";").first.split('-').first }.uniq
    return default if accepted_languages.blank?
     
    possible_languages = active_languages.map { |x| x.locale_name.match(/\w{2}/).to_s }
    prefered_languages = accepted_languages & possible_languages
    
    return default if prefered_languages.blank?
    
    prefered_language = active_languages.detect { |x| !!(x.locale_name =~ /^#{prefered_languages.first}/) }
    
    return prefered_language
  end
end

