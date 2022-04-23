import random

random_array = []

for i in range(10):
    num = random.randint(0, 2)
    random_array.append(num)

print(random_array)

random_array = []

while True:
    num = random.randint(0, 9)
    if num not in random_array:
        random_array.append(num)
    if len(random_array) == 10:
        break

print(random_array)