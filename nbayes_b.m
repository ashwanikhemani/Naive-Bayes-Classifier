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

function retval = classify (msg,train_spam_num,train_ham_num,numspamwords,numhamwords,spamcounts,hamcounts,alpha)
  pspam=train_spam_num/(train_spam_num+train_ham_num);
  pham=train_ham_num/(train_spam_num+train_ham_num);
  isspam=pspam*cond_prob_Msg(msg,"spam",spamcounts,hamcounts,numspamwords,numhamwords,alpha);
  isham=pham*cond_prob_Msg(msg,"ham",spamcounts,hamcounts,numspamwords,numhamwords,alpha);
  retval=(isspam>isham);
endfunction


function retval1 = cond_prob_Msg (msg,label,spamcounts,hamcounts,numspamwords,numhamwords,alpha)
    prob_label_msg = 1.0;
    for q=1:length(msg)
      prob_label_msg *= cond_prob_word(msg(q),label,spamcounts,hamcounts,numspamwords,numhamwords,alpha);
    endfor
    retval1=prob_label_msg ;
endfunction

function retval2 = cond_prob_word(word,label,spamcounts,hamcounts,numspamwords,numhamwords,alpha)
  if(strcmp(label,"spam"))
    a=cell2mat(word);
    current_count = spamcounts.get(a);
    if (isempty(current_count))
      retval2=(alpha)/(numspamwords+alpha*20000);  % probability of word given spam
    else
      retval2=(spamcounts.get(a)+alpha)/(numspamwords+alpha*20000);  % probability of word given spam
    end
  else
    b=cell2mat(word);
    current_count1 = hamcounts.get(b);
    if (isempty(current_count1))
      retval2=(alpha)/(numhamwords+alpha*20000); % probability of word  given ham
    else
      retval2=(hamcounts.get(b)+alpha)/(numhamwords+alpha*20000);  % probability of word given spam
    end
  end
endfunction

prediction=[];
actual=[];
x=length(test_examples);
i=[-5,-4,-3,-2,-1,0];
te=[];
tef=[];
tra=[];
trf=[];
for t = i 
  alpha=power(2,t);
  for (z=1:length(train_examples))
    for (j=1:length(train_examples(z).words))
        word = train_examples(z).words{j};
        if (train_examples(z).spam == 1)
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
    % test examples, calculating Tp, Fp, Tn and Fn
    test_TruePositive=0;
    test_FalsePositive=0;
    test_TrueNegative=0;
    test_FalseNegative=0;
  for p=1:x
    pred=classify(test_examples(p).words,train_spam_num,train_ham_num,numspamwords,numhamwords,spamcounts,hamcounts,alpha);
    if(pred==1) % classifier predicted spam 
      if(test_examples(p).spam==1) % actual msg is spam 
        test_TruePositive=test_TruePositive+1;
      else   % actual msg is ham 
        test_FalsePositive=test_FalsePositive+1;
      end
    else  % classifier predicted ham
      if(test_examples(p).spam==1) % actual msg is spam
        test_FalseNegative=test_FalseNegative+1;
      else  % actual msg is ham
        test_TrueNegative=test_TrueNegative+1;
      end
    end
    prediction=[prediction,pred];
    actual=[actual,test_examples(p).spam];
  endfor

  test_precision=test_TruePositive/(test_TruePositive+test_FalsePositive);
  test_recall=test_TruePositive/(test_TruePositive+test_FalseNegative);
  test_fscore=2*(test_precision*test_recall)/(test_precision+test_recall);
  test_error = (mean(prediction~=actual))*100;
  test_accuracy=100-test_error;
  te=[te,test_accuracy];
  tef=[tef,test_fscore];

    %train_examples
    % train_examples , calculating Tp, Fp, Tn and Fn
  train_TruePositive=0;
  train_FalsePositive=0;
  train_TrueNegative=0;
  train_FalseNegative=0;
  for p=1:length(train_examples)
    pred=classify(train_examples(p).words,train_spam_num,train_ham_num,numspamwords,numhamwords,spamcounts,hamcounts,alpha);
    if(pred==1) % classifier predicted spam 
      if(train_examples(p).spam==1) % actual msg is spam 
        train_TruePositive=train_TruePositive+1;
      else   % actual msg is ham 
        train_FalsePositive=train_FalsePositive+1;
      end
    else  % classifier predicted ham
      if(train_examples(p).spam==1) % actual msg is spam
        train_FalseNegative=train_FalseNegative+1;
      else  % actual msg is ham
        train_TrueNegative=train_TrueNegative+1;
      end
    end
    prediction=[prediction,pred];
    actual=[actual,train_examples(p).spam];
  endfor
  train_precision=train_TruePositive/(train_TruePositive+train_FalsePositive);
  train_recall=train_TruePositive/(train_TruePositive+train_FalseNegative);
  train_fscore=2*(train_precision*train_recall)/(train_precision+train_recall);
  train_error = (mean(prediction~=actual))*100;
  train_accuracy=100-train_error;
  tra=[tra,train_accuracy];
  trf=[trf,train_fscore];

endfor
% Plotting

i=[-5,-4,-3,-2,-1,0];
plot(i,te,'b');
hold on
plot(i,tra,'r');
xlabel('i');
ylabel('Accuracy');
title("Accuracy plot");
legend('Test Accuracy','Train Accuracy');

figure;

plot(i,tef,'b');
hold on
plot(i,trf,'r');
xlabel('i');
ylabel('F-Score');
title("F-Score plot");
legend('Test F-Score','Train F-Score');