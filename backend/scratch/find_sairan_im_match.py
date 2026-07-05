import os

def main():
    for root, dirs, files in os.walk('c:/Users/Asus/Desktop/test'):
        for f in files:
            if 'seed_tournaments' in f:
                print(os.path.join(root, f))

if __name__ == '__main__':
    main()
