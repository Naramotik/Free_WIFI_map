package com.example.demo.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "complain")
public class Complain {

    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;
    @Column(name = "complain")
    String complain;
    @ManyToOne
    @JoinColumn(name = "mark_longitude")
    Mark mark;
    @ManyToOne
    @JoinColumn(name = "client_id")
    Client client;
}
