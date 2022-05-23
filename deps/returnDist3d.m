function distL = returnDist3d(J1,J2)
distL = sqrt(sum((J1-J2).^2,2));
end
