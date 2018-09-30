function invma=finv()
mat=mulalter();
invma=zeros(60,1);
for i=1:60
    ind=find(mat(i,:)==1);
    invma(i)=ind;
end