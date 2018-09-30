F11=randi([0,256],12,1);
filter=randi([0,256],12,1);
W1=zeros(12,1);
W2=zeros(12,1);
W3=zeros(12,1);
W4=zeros(12,1);
invv=finv();
mat=mulalter();
indexx=mat(7,:);
F12=F11(indexx');
for i=1:12
    indd=mat(:,i);
    ind=indd(invv);
    W1(i)=(F11(:)')*filter(ind);
    W2(i)=(F12(:)')*filter(ind);
   
end
figure(1)
plot(W1);
figure(2)
plot(W2);
figure(3)
plot(W1(indexx'))
% figure(4)
% plot(W3);
% figure(5)
% plot(W4);


