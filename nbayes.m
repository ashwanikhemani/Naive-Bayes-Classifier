fid = fopen('SMSSpamCollection');            % read file
data = fread(fid);
fclose(fid);
lcase = abs('a'):abs('z');
ucase = abs('A'):abs('Z');
caseDiff = abs('a') - abs('A');
caps = ismember(data,ucase);
data(caps) = data(caps)+caseDiff;     % convert to lowercase
data(data == 9) = abs(' ');          % convert tabs to spaces
validSet = [9 10 abs(' ') lcase];         
data = data(ismember(data,validSet)); % remove non-space, non-tab, non-(a-z) characters
data = char(data);                    % convert from vector to characters

words = strsplit(data') ;          % split into words

% split into examples
count = 0;
examples = {};

for (i=1:length(words))
   if (strcmp(words{i}, 'spam') || strcmp(words{i}, 'ham'))
       count = count+1;
       examples(count).spam = strcmp(words{i}, 'spam');
       examples(count).words = [];
   else
       examples(count).words{length(examples(count).words)+1} = words{i};
   end
end
examples
%split into training and test
random_order = randperm(length(examples));
train_examples = examples(random_order(1:floor(length(examples)*.8)));
test_examples = examples(random_order(floor(length(examples)*.8)+1:end));
% count occurences for spam and ham

spamcounts = javaObject('java.util.HashMap');
numspamwords = 0;
hamcounts = javaObject('java.util.HashMap');
numhamwords = 0;

alpha = 0.1;

for (i=1:length(train_examples))
    for (j=1:length(train_examples(i).words))
        word = train_examples(i).words{j};
        if (train_examples(i).spam == 1)
            numspamwords = numspamwords+1;
            current_count = spamcounts.get(word);
            if (isempty(current_count))
                spamcounts.put(word, 1+alpha);    % initialize by including pseudo-count prior
            else
                spamcounts.put(word, current_count+1);  % increment
            end
        else
            numhamwords = numhamwords+1;
            current_count = hamcounts.get(word);
            if (isempty(current_count))
                hamcounts.put(word, 1+alpha);    % initialize by including pseudo-count prior
            else
                hamcounts.put(word, current_count+1);  % increment
            end
        end
    end    
end
spamcounts.get('free')/(numspamwords+alpha*20000) ;  % probability of word 'free' given spam
hamcounts.get('free')/(numhamwords+alpha*20000)  ; % probability of word 'free' given ham
% will need to check if count is empty!

% ... 
train_spam_num=0;
train_ham_num=0;
for (k=1:length(train_examples))
    if (train_examples(k).spam == 1)
       train_spam_num = train_spam_num + 1;
    else
       train_ham_num = train_ham_num + 1;
    end    
end 

function retval = classify (msg,train_spam_num,train_ham_num,numspamwords,numhamwords,spamcounts,hamcounts)
  pspam=train_spam_num/(train_spam_num+train_ham_num);
  pham=train_ham_num/(train_spam_num+train_ham_num);
  isspam=pspam*cond_prob_Msg(msg,"spam",spamcounts,hamcounts,numspamwords,numhamwords);
  isham=pham*cond_prob_Msg(msg,"ham",spamcounts,hamcounts,numspamwords,numhamwords);
  retval=(isspam>isham);
endfunction


function retval1 = cond_prob_Msg (msg,label,spamcounts,hamcounts,numspamwords,numhamwords)
    prob_label_msg = 1.0;
    for q=1:length(msg)
      prob_label_msg *= cond_prob_word(msg(q),label,spamcounts,hamcounts,numspamwords,numhamwords);
    endfor
    retval1=prob_label_msg ;
endfunction

function retval2 = cond_prob_word(word,label,spamcounts,hamcounts,numspamwords,numhamwords)
  if(strcmp(label,"spam"))
    a=cell2mat(word);
    current_count = spamcounts.get(a);
    if (isempty(current_count))
      retval2=(0.1)/(numspamwords+0.1*20000);  % probability of word given spam
    else
      retval2=(spamcounts.get(a)+0.1)/(numspamwords+0.1*20000);  % probability of word given spam
    end
  else
    b=cell2mat(word);
    current_count1 = hamcounts.get(b);
    if (isempty(current_count1))
      retval2=(0.1)/(numhamwords+0.1*20000); % probability of word  given ham
    else
      retval2=(hamcounts.get(b)+0.1)/(numhamwords+0.1*20000);  % probability of word given spam
    end
  end
endfunction

prediction=[];
actual=[];
x=length(test_examples);
tp=0;
tn=0;
fp=0;
fn=0;
for p=1:x
  pred=classify(test_examples(p).words,train_spam_num,train_ham_num,numspamwords,numhamwords,spamcounts,hamcounts);
  if(pred==1) % classifier predicted spam 
    if(test_examples(p).spam==1) % actual msg is spam 
      tp=tp+1;
    else   % actual msg is ham 
      fp=fp+1;
    end
  else  % classifier predicted ham
    if(test_examples(p).spam==1) % actual msg is spam
      fn=fn+1;
    else  % actual msg is ham
      tn=tn+1;
    end
  end
  prediction=[prediction,pred];
  actual=[actual,test_examples(p).spam];
endfor
precision=tp/(tp+fp);
recall=tp/(tp+fn);
fscore=2*(precision*recall)/(precision+recall);
test_error = (mean(prediction~=actual))*100;
test_accuracy=100-test_error;
fprintf("\nPrecision: %f percent",(precision*100));
fprintf("\nRecall: %f percent",(recall*100));
fprintf("\nF_Score: %f percent",(fscore*100));
fprintf("\nAccuracy: %f percent\n",(test_accuracy));

