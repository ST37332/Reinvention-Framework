-- @ JOB CATEGORIES

CAT_TEST1 = 1
CAT_TEST2 = 2

re.Jobs:AddCategory(CAT_TEST1, {
    name = 'Test Category #1',
    sortO = 100,
    color = Color(0, 0, 255)
})

re.Jobs:AddCategory(CAT_TEST2, {
    name = 'Test Category #2',
    sortO = 50,
    color = Color(255, 0, 0)
})