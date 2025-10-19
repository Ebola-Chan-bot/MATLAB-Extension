%[text] 猜密码游戏
%[text] 根据条件猜测指定位数的数字密码。条件可以调用时手动输入，也可以不指定而在交互时输入。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] Guesses = MATLAB.GuessPassword;
%[text] %完全交互式地进行猜密码游戏
%[text]
%[text] Guesses = MATLAB.GuessPassword(Digits);
%[text] %猜指定位数的密码
%[text]
%[text] Guesses = MATLAB.GuessPassword(Conditions);
%[text] %指定预先猜测的几个密码
%[text] ```
%[text] ## 输入参数
%[text] Digits(1,1)，密码位数
%[text] Conditions table，预先猜测的密码和猜测结果，一行一个猜测。必须包含以下列：
%[text] - Guess(:,:)char，猜测密码。所有猜测必须等宽。
%[text] - DigitCorrects(:,1)，有几个数字正确，不能多于密码位数，即Guess宽度
%[text] - PositionCorrects(:,1)，数字正确中，有几个位置也正确，不能多于DigitCorrects \
%[text] ## 返回值
%[text] Guesses(:,:)char，所有可能正确的密码，一行一个密码。
function Guesses = GuessPassword(Conditions)
if nargin
    if istable(Conditions)
        Digits=width(Conditions.Guess);
    else
        Digits=Conditions;
        Conditions=table;
    end
else
    Digits=str2double(inputdlg('请输入密码的位数：','猜密码游戏',1,"4"));
    Conditions=table;
end
Guesses=compose(['%0',num2str(Digits),'u'],0:10^Digits-1);
Guesses=vertcat(Guesses{:});
NumConditions=height(Conditions);
C=0;
while height(Guesses)>1&&C<NumConditions
    C=C+1;
    G=Conditions.Guess(C,:);
    Guesses(sum(Guesses==G,2)~=Conditions.PositionCorrects(C),:)=[];
    Guesses(sum(min(CharCount(Guesses),CharCount(G)),3)~=Conditions.DigitCorrects(C),:)=[];
end
while height(Guesses)>1
    GuessesLeft=height(Guesses);
    GDP=inputdlg([sprintf("还有%u种可能，输入一个猜测以继续筛选，不输入则立即返回所有可能密码：",GuessesLeft);"几个数字正确？如果有重复数字，计重复数较少的一边：";"其中有几个位置也正确？"],'继续筛选密码',1,[string(Guesses(randi(GuessesLeft),:));"";""]);
    if isempty(GDP{1})
        break;
    end
    Guesses(sum(Guesses==GDP{1},2)~=str2double(GDP{3}),:)=[];
    Guesses(sum(min(CharCount(Guesses),CharCount(GDP{1})),3)~=str2double(GDP{2}),:)=[];
end
end
function CC=CharCount(Chars)
persistent CountMap
if isempty(CountMap)
    CountMap=reshape('0':'9',1,1,[]);
end
CC=sum(Chars==CountMap,2);
end

%[appendix]{"version":"1.0"}
%---
