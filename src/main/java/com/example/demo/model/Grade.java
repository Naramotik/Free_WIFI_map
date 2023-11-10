package com.example.demo.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "grade")
@Builder
public class Grade {
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;
    @Column(name = "score")
    Integer score;
    @ManyToOne
    @JoinColumn(name = "mark_longitude")
    Mark mark;
    @ManyToOne
    @JoinColumn(name = "client_id")
    Client client;
}
