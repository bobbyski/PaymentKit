Pod::Spec.new do |s|
  s.name                  = "PaymentKit"
  s.version               = "1.1.3"
  s.summary               = "Utility library for creating credit card payment forms."
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage              = "https://github.com/bobbyski/PaymentKit"
  s.author                = { "Alex MacCaw" => "alex@stripe.com",
                 			  "Bobby Skinner"     => "bobbyski@gmail.com" }
  s.source                = { :git => "https://github.com/bobbyski/PaymentKit.git", :tag => "v1.1.3"}
  s.source_files          = 'PaymentKit/*.{h,m}'
  s.public_header_files   = 'PaymentKit/*.h'
  s.resources             = 'PaymentKit/Resources/Cards/*.png', 'PaymentKit/Resources/*.png'
  s.platform              = :ios
  s.requires_arc          = true
  s.ios.deployment_target = '5.0'
end
