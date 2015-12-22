require 'statsample'
require 'descriptive_statistics'




Statsample::Analysis.store(Statsample::Test::T) do
  a= 100.times.map {rand(100)}
  b= 100.times.map {rand(100)}
  t_1=Statsample::Test::T.two_sample_independent(a.mean, b.mean,
  			      a.standard_deviation, b.standard_deviation,
  			      							100, 100)
  summary t_1
end

Statsample::Analysis.run_batch

