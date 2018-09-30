function per=matpermu(level)
loc=originalco(level);
[alter,altermatri,alterot]=alter52();
per=[];
for i=1:60
    R=alterot{i};
    newloc=R*loc';
    newp=[];
    for j=1:size(newloc,2)
        vec=sum(abs(loc'-newloc(:,j)));
        ind=find(vec<1e-4);
        newp=[newp;ind];
    end
    per=[per,newp];
end

