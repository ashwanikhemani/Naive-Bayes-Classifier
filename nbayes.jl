# read file
file = open("SMSSpamCollection")            # read file
lines = readlines(file)

# filter characters
lines = map(x -> lowercase(x), lines)       # convert to lowercase
valid(str) = filter(                        # function to filter non-space, non-tab, non-(a-z) characters
      x -> (x >= 'a' && x <= 'z')
            || x == '\t' || x == ' ', str)
lines = map(x -> valid(x), lines)           # apply filter to data
n_all = length(lines)                       # total samples

# create examples and labels
label = zeros(Int, n_all)                   # vector cointaining the label (1=spam/0=ham)
examples = Vector{Vector{ASCIIString}}()    # vector cointaining data (sentences)
for i=1:n_all
  words = split(lines[i])
  if words[1] == "spam"                     # if the first word is spam
    label[i] = 1
  end
  push!(examples, words[2:end])             # add thesentence (vector of words) to examples
end

# split into training and test
random_order = randperm(n_all)
train_examples = examples[random_order[1 : floor(Int, n_all * 0.8)]]
train_label = label[random_order[1 : floor(Int, n_all * 0.8)]]
test_examples = examples[random_order[floor(Int, n_all * 0.8)+1 : end]]
test_label = label[random_order[floor(Int, n_all * 0.8)+1 : end]]

# count occurences for spam and ham
spamcounts = Dict{ASCIIString,Float64}()
numspamwords = 0
hamcounts = Dict{ASCIIString,Float64}()
numhamwords = 0

alpha = 0.1

for i=1:length(train_examples)
  for j=1:length(train_examples[i])
    word = train_examples[i][j]
    if train_label[i] == 1
      numspamwords += 1
      if !haskey(spamcounts, word)
        spamcounts[word] = 1+alpha          # initialize by including pseudo-count prior
      else
        spamcounts[word] += 1               # increment
      end
    else
      numhamwords += 1
      if !haskey(hamcounts, word)
        hamcounts[word] = 1+alpha           # initialize by including pseudo-count prior
      else
        hamcounts[word] += 1                # increment
      end
    end
  end
end

println(spamcounts["free"]/(numspamwords + alpha * 20000))   # probability of word 'free' given spam
println(hamcounts["free"]/(numhamwords + alpha * 20000))     # probability of word 'free' given ham
# will need to check if count is empty!

# ...
