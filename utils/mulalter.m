function [mat,all]=mulalter()
[alter, altermatri]=alter5();
all=cell(60);
mat=zeros(60,60);
for i=1:60
    for j=1:60
        aa=abs(alter-altermatri{i}*altermatri{j}*[1:12]');
        aa=sum(aa);
        a2=find(aa==0);
        all{i,j}=altermatri{a2};
        mat(i,j)=a2;
    end
end




