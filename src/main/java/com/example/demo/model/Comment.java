package com.example.demo.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "comment")
public class Comment {

    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;
    @Column(name = "comment")
    String comment;
    @ManyToOne
    @JoinColumn(name = "mark_longitude")
    Mark mark;
    @ManyToOne
    @JoinColumn(name = "client_id")
    Client client;
}