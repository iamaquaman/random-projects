def fibunacci():
    a, b = 1, 1
    while b < 50:
        print(b)
        a, b = b, a + b
        
fibunacci()