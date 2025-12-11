//
//  Models.swift
//  WidgetExtension
//
//  Created by Zhiyuan Ding on 12/9/25.
//

import Foundation

struct Announcement: Identifiable, Codable {
    var id: String { link.absoluteString }
    let date: String
    let title: String
    let course: String
    let link: URL

    enum CodingKeys: String, CodingKey {
        case date, title, course, link
    }
}

struct Assignment: Identifiable, Codable {
    var id: String { link.absoluteString }
    let course: String
    let title: String
    let dueDate: String
    let link: URL

    enum CodingKeys: String, CodingKey {
        case course, title, link
        case dueDate = "due_date"
    }
}

func sampleAnnouncements() -> [Announcement] {
    return [
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Assignment Due Tomorrow",
            course: "CS 101",
            link: URL(string: "https://canvas.example.com/courses/1/assignments/1")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "New Reading Material Posted",
            course: "Math 205",
            link: URL(string: "https://canvas.example.com/courses/2/pages/reading")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Office Hours Changed",
            course: "Physics 301",
            link: URL(string: "https://canvas.example.com/courses/3/discussion_topics/1")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Midterm Exam Scheduled",
            course: "History 150",
            link: URL(string: "https://canvas.example.com/courses/4/quizzes/1")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Lab Report Due Friday",
            course: "Chemistry 220",
            link: URL(string: "https://canvas.example.com/courses/5/assignments/2")!
        ),
        Announcement(
            date: "Dec 9 at 6:49pm",
            title: "Group Project Guidelines",
            course: "English 305",
            link: URL(string: "https://canvas.example.com/courses/6/assignments/3")!
        )
    ]
}

func sampleAssignments() -> [Assignment] {
    return [
        Assignment(
            course: "EN.580.680.01.FA25",
            title: "Assignment Created - Teammate Evaluation Form, Precision Care Medicine",
            dueDate: "Dec 15 by 9pm",
            link: URL(string: "https://jhu.instructure.com/courses/102501/announcements/1142916")!
        ),
        Assignment(
            course: "CS 101",
            title: "Homework 1",
            dueDate: "Dec 12 by 11:59pm",
            link: URL(string: "https://canvas.example.com/courses/1/assignments/101")!
        ),
        Assignment(
            course: "Math 205",
            title: "Problem Set 3",
            dueDate: "Dec 14 by 5pm",
            link: URL(string: "https://canvas.example.com/courses/2/assignments/201")!
        )
    ]
}
