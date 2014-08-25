% Compute Correlation between two images using the 
% similarity measure of Sum of Absolute Differences (SAD) with
% Right Image as reference.

% @author: Nicola Dal Lago
% @date: 01/08/2014
% @version: 1.0

function dispMap=funcSADR2L(leftImage, rightImage, windowSize, dispMin, dispMax)

    leftImage = rgb2gray(imread(leftImage));
    leftImage = double(leftImage);
    
    rightImage = rgb2gray(imread(rightImage));
    rightImage = double(rightImage);
   
    [columns, rows] = size(leftImage);
    
    dispMap = zeros(columns, rows);

    win = (windowSize - 1)/2;
    for(i=1+win : 1 : columns-win)
        for(j=1+win : 1 : rows-win-dispMax)
            prevSAD = 65532;
            temp=0;
            bestMatchSoFar = dispMin;
            for(dispRange=dispMin : 1 : dispMax)
                sad=0;
                for(a=-win : 1 : win)
                    for(b=-win : 1 : win)
                        if (j + b + dispRange <= rows)
                            temp = rightImage(i+a, j+b) - leftImage(i+a, j+b+dispRange);
                            if(temp < 0)
                                temp = temp *- 1;
                            end
                            sad = sad + temp;
                        end
                    end
                end
                if (prevSAD > sad)
                    prevSAD = sad;
                    bestMatchSoFar = dispRange;
                end
            end
            dispMap(i,j) = bestMatchSoFar;
        end
    end