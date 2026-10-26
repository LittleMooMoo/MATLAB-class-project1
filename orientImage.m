function hatImage = orientImage(hatImage,command)
    switch command
        case 2
            hatImage = rot90(hatImage,1);   % counterclockwise
        case 3
            hatImage = flipud(hatImage); 
        case 4 
            hatImage = rot90(hatImage,-1);  % clockwise
        case 5 
            hatImage = flipud(hatImage); 
    end
end
