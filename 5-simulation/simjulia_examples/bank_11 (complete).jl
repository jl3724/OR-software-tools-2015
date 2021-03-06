using Distributions
using SimJulia

# Model components

function visit(customer::Process, time_in_bank::Float64, clerk::Resource)
	arrive = now(customer)
	@printf("%8.3f %s: Here I am\n", arrive, customer)
	request(customer, clerk) # waiting for the server
	wait = now(customer) - arrive
	@printf("%8.3f %s: Waited %6.3f\n", now(customer), customer, wait)
	hold(customer, time_in_bank) # using the server
	release(customer, clerk) # finish service
	@printf("%8.3f %s: Finished\n", now(customer), customer)
end

function generate(source::Process, number::Int64, mean_time_between_arrivals::Float64, mean_time_in_bank::Float64, clerk::Resource)
	d_tba = Exponential(mean_time_between_arrivals)
	d_tib = Exponential(mean_time_in_bank)
	for i = 1:number
		c = Process(simulation(source), @sprintf("Customer%02d", i))
		tib = rand(d_tib)
		activate(c, now(source), visit, tib, clerk)
		tba = rand(d_tba)
		hold(source, tba)
	end
end

# Experiment data

max_number = 5
max_time = 400.0
mean_time_between_arrivals = 10.0
mean_time_in_bank = 12.0
theseed = 99999
srand(theseed)

# Model/Experiment

sim = Simulation(uint(16))
k = Resource(sim, "Counter", uint(1), true) # set "monitered=true"
s = Process(sim, "Source")
activate(s, 0.0, generate, max_number, mean_time_between_arrivals, mean_time_in_bank, k)
run(sim, max_time)

# Print result
println("TimeAverage no. waiting: $(time_average(wait_monitor(k)))")
println("TimeAverage no. in service: $(time_average(activity_monitor(k)))")
