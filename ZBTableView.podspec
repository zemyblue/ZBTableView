Pod::Spec.new do |s|
  s.name         = "ZBTableView"
  s.version      = "0.1.0"
  s.summary      = "Simple tableView that can pull down or pull up refresh."
# s.description  = "Simple tableView that can pull down or pull up refresh."
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author       = { "zemyblue" => "zemyblue@gmail.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/zemyblue/ZBTableView.git", :tag => "v#{s.version}" }
  s.requires_arc = true
  s.source_files = "ZBTableView"
  s.requires_arc = true
end
