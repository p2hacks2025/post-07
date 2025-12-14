from generate_searchword import generate_searchword
from searchX import search


def handle_tribiasearch(tribia):
    judgetext = generate_searchword(tribia)
    print(judgetext)
    kekka = search(tribia,judgetext)


    print(kekka)





if __name__ == "__main__":
    handle_tribiasearch("タコの心臓は3個ある")
