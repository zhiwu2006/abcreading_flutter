import '../models/lesson.dart';

final List<Lesson> defaultLessons = [
  Lesson(
    lesson: 1,
    title: "Sally's Dog",
    content: """Sally wants a dog. Can I have a dog? Sally asks mom and dad.

We live in an apartment. Dogs need space to run and play. We don't have a yard, mom says.

But I will walk the dog every day! I will feed the dog! I will take care of the dog! Sally says.

Dogs are a big responsibility, dad says. You have to walk them every day, even when it's raining or snowing.

I know! I really want a dog! Sally says.

Mom and dad talk about it. They decide to visit the animal shelter to look at dogs.

At the animal shelter, Sally sees many dogs. There are big dogs and small dogs. There are old dogs and young dogs.

Sally sees a small brown dog. The dog is very friendly. The dog licks Sally's hand.

This dog is perfect! Sally says. Can we take him home?

The dog needs a good home, says the worker at the animal shelter. You seem like a nice family.

Sally's family takes the dog home. Sally names the dog Buddy.

Sally takes good care of Buddy. She walks him every day. She feeds him every day. She plays with him every day.

Sally is very happy with her new dog. Buddy is very happy with his new family.""",
    vocabulary: [
      Vocabulary(word: "apartment", meaning: "公寓"),
      Vocabulary(word: "responsibility", meaning: "责任"),
      Vocabulary(word: "shelter", meaning: "收容所"),
      Vocabulary(word: "friendly", meaning: "友好的"),
      Vocabulary(word: "perfect", meaning: "完美的"),
    ],
    sentences: [
      Sentence(
        text: "Dogs are a big responsibility.",
        note: "这句话表达了养狗是一个重大责任的意思。'responsibility'是名词，意为责任。",
      ),
      Sentence(
        text: "You have to walk them every day.",
        note: "这是一个表示义务的句子，'have to'表示必须，后面跟动词原形。",
      ),
    ],
    questions: [
      Question(
        question: "Where does Sally live?",
        options: QuestionOptions.fromOptions(
          A: "In a house with a big yard",
          B: "In an apartment",
          C: "On a farm",
          D: "In a hotel",
        ),
        answer: "B",
      ),
      Question(
        question: "What does Sally promise to do for the dog?",
        options: QuestionOptions.fromOptions(
          A: "Only feed the dog",
          B: "Only walk the dog",
          C: "Walk, feed, and take care of the dog",
          D: "Nothing",
        ),
        answer: "C",
      ),
      Question(
        question: "What is the name of Sally's dog?",
        options: QuestionOptions.fromOptions(
          A: "Max",
          B: "Charlie",
          C: "Buddy",
          D: "Rex",
        ),
        answer: "C",
      ),
    ],
  ),
  Lesson(
    lesson: 2,
    title: "The School Library",
    content: """Tom loves to read books. Every day after school, he goes to the school library.

The school library is a quiet place. Students come here to read books and do homework.

Mrs. Johnson is the librarian. She helps students find books. She knows where every book is in the library.

Tom likes adventure books. He also likes books about animals and science.

Today, Tom is looking for a book about dinosaurs. He asks Mrs. Johnson for help.

The dinosaur books are in the science section, Mrs. Johnson says. Follow me.

Mrs. Johnson shows Tom many books about dinosaurs. Tom picks a book called "Amazing Dinosaurs."

Tom sits at a table and starts reading. He learns about different types of dinosaurs. Some dinosaurs were very big. Some dinosaurs were very small.

Tom reads about T-Rex, the king of dinosaurs. T-Rex had big teeth and small arms.

Tom also reads about Triceratops. Triceratops had three horns on its head.

After one hour, Tom has to go home. He wants to take the book home to finish reading it.

Can I borrow this book? Tom asks Mrs. Johnson.

Of course! You can keep it for two weeks, Mrs. Johnson says. She scans the book with a computer.

Tom is very happy. He can't wait to read more about dinosaurs at home.

The next day, Tom tells his friends about the dinosaur book. His friends want to read dinosaur books too.""",
    vocabulary: [
      Vocabulary(word: "library", meaning: "图书馆"),
      Vocabulary(word: "librarian", meaning: "图书管理员"),
      Vocabulary(word: "adventure", meaning: "冒险"),
      Vocabulary(word: "dinosaurs", meaning: "恐龙"),
      Vocabulary(word: "borrow", meaning: "借"),
    ],
    sentences: [
      Sentence(
        text: "Every day after school, he goes to the school library.",
        note: "这句话使用了一般现在时，表示习惯性动作。'every day'表示每天。",
      ),
      Sentence(
        text: "She knows where every book is in the library.",
        note: "这是一个宾语从句，'where every book is'作为know的宾语。",
      ),
    ],
    questions: [
      Question(
        question: "What does Tom like to do?",
        options: QuestionOptions.fromOptions(
          A: "Play sports",
          B: "Read books",
          C: "Watch TV",
          D: "Play games",
        ),
        answer: "B",
      ),
      Question(
        question: "Who is Mrs. Johnson?",
        options: QuestionOptions.fromOptions(
          A: "Tom's teacher",
          B: "Tom's mother",
          C: "The librarian",
          D: "Tom's friend",
        ),
        answer: "C",
      ),
      Question(
        question: "How long can Tom keep the book?",
        options: QuestionOptions.fromOptions(
          A: "One day",
          B: "One week",
          C: "Two weeks",
          D: "One month",
        ),
        answer: "C",
      ),
      Question(
        question: "What book does Tom choose?",
        options: QuestionOptions.fromOptions(
          A: "Amazing Animals",
          B: "Amazing Dinosaurs",
          C: "Amazing Science",
          D: "Amazing Adventures",
        ),
        answer: "B",
      ),
    ],
  ),
  Lesson(
    lesson: 3,
    title: "Emma's Birthday Party",
    content: """Today is Emma's birthday. She is turning eight years old. Emma is very excited about her birthday party.

Emma's mom has been planning the party for weeks. She bought balloons, decorations, and a big chocolate cake.

The party starts at two o'clock in the afternoon. Emma's friends start arriving at her house.

First, Sarah arrives with a present wrapped in pink paper. Then, Mike comes with his mom. After that, Lisa and Jenny arrive together.

All of Emma's friends sing "Happy Birthday" to her. Emma makes a wish and blows out the candles on her cake.

What did you wish for? Sarah asks.

I can't tell you, or it won't come true! Emma says with a smile.

Emma's mom cuts the cake and gives everyone a piece. The chocolate cake is delicious. Everyone loves it.

After eating cake, the children play party games. They play musical chairs, pin the tail on the donkey, and hide and seek.

Emma's favorite game is musical chairs. When the music stops, everyone tries to sit in a chair. The person without a chair is out.

Then it's time to open presents. Emma gets many wonderful gifts. Sarah gives her a new book. Mike gives her a puzzle. Lisa gives her art supplies. Jenny gives her a stuffed animal.

Thank you so much for all the presents! Emma says. This is the best birthday ever!

At the end of the party, Emma's mom gives each friend a goodie bag with candy and small toys.

All of Emma's friends had a great time at the party. Emma is very happy and tired after her special day.""",
    vocabulary: [
      Vocabulary(word: "excited", meaning: "兴奋的"),
      Vocabulary(word: "decorations", meaning: "装饰品"),
      Vocabulary(word: "wrapped", meaning: "包装的"),
      Vocabulary(word: "candles", meaning: "蜡烛"),
      Vocabulary(word: "delicious", meaning: "美味的"),
    ],
    sentences: [
      Sentence(
        text: "She is turning eight years old.",
        note: "这里用现在进行时表示即将发生的动作，'turn'在这里表示'变成'的意思。",
      ),
      Sentence(
        text: "I can't tell you, or it won't come true!",
        note: "这是一个条件句，'or'在这里表示'否则'的意思，后面用将来时。",
      ),
    ],
    questions: [
      Question(
        question: "How old is Emma turning?",
        options: QuestionOptions.fromOptions(
          A: "Seven years old",
          B: "Eight years old",
          C: "Nine years old",
          D: "Ten years old",
        ),
        answer: "B",
      ),
      Question(
        question: "What time does the party start?",
        options: QuestionOptions.fromOptions(
          A: "One o'clock",
          B: "Two o'clock",
          C: "Three o'clock",
          D: "Four o'clock",
        ),
        answer: "B",
      ),
      Question(
        question: "What is Emma's favorite party game?",
        options: QuestionOptions.fromOptions(
          A: "Hide and seek",
          B: "Pin the tail on the donkey",
          C: "Musical chairs",
          D: "Tag",
        ),
        answer: "C",
      ),
      Question(
        question: "What does Sarah give Emma as a present?",
        options: QuestionOptions.fromOptions(
          A: "A puzzle",
          B: "Art supplies",
          C: "A stuffed animal",
          D: "A new book",
        ),
        answer: "D",
      ),
    ],
  ),
];