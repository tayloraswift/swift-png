import func Foundation.exit

var failed = false 
for (name, function):(String, Test.Function) in Test.cases 
{
    guard let _:Void = test(function, name: name)
    else 
    {
        failed = true 
        continue 
    }
}

failed ? Foundation.exit(-1) : Foundation.exit(0)
