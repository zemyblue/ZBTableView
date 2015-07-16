Pod::Spec.new do |s|
  s.name         = "ZBTableView"
  s.version      = "0.2.0"
  s.summary      = "Simple tableView that can pull down or pull up refresh."
# s.description  = "Simple tableView that can pull down or pull up refresh."
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "zemyblue" => "zemyblue@gmail.com" }
  s.homepage     = 'https://github.com/zemyblue/ZBTableView'
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/zemyblue/ZBTableView.git", :tag => "#{s.version}" }
  s.requires_arc = true
  s.source_files = "ZBTableView"
  s.requires_arc = true
end
