package com.example.demo;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "mark")
public class Mark {
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;
    @Column(name = "latitude")
    String latitude;
    @Column(name = "longitude")
    String longitude;
    @JsonIgnore
    @OneToMany(mappedBy = "mark")
    private List<Comment> comments;
    @JsonIgnore
    @OneToMany(mappedBy = "mark")
    private List<Complain> complains;
}
