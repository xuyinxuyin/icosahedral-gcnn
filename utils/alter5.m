function [alter,altermatri]=alter5()
a=zeros(12,12);
a(1,7)=1;
a(2,11)=1;
a(3,12)=1;
a(4,5)=1;
a(5,4)=1;
a(6,8)=1;
a(7,1)=1;
a(8,6)=1;
a(9,10)=1;
a(10,9)=1;
a(11,2)=1;
a(12,3)=1;
blist=[2,7,6,5,10,11,1,9,12,4,3,8];
b=zeros(12,12);
for i=1:12
    b(i,blist(i))=1;
end
A1=eye(12,12);
A2=a;
A3=b;
A4=b*a;
A5=b*a*b;
A6=b*a*b*a*b;
A7=b*a*b*a;
A8=b*a*b*a*b*a;
A9=b*a*b*a*b*b;
A10=b*a*b*a*b*b*a;
A11=b*a*b*a*b*b*a*b*a;
A12=b*a*b*a*b*b*a*b;
AA={A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12};
c=a*b;
alter=[];
altermatri=cell(60,1);
for i=1:12
    for j=0:4
        list=(c)^j*AA{i}*[1:12]';
        alter=[alter,list];
        altermatri{5*(i-1)+j+1}=(c)^j*AA{i};
    end
end

